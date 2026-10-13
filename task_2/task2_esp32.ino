#include <Arduino.h>
#include <driver/i2s.h>

#define I2S_PORT I2S_NUM_0
constexpr int I2S_SCK = 26;
constexpr int I2S_WS  = 25;
constexpr int I2S_SD  = 33;
constexpr uint32_t SAMPLE_RATE = 16000;
constexpr uint16_t BLOCK_SIZE = 1024;
constexpr uint16_t FORMAT_INT32 = 1;
constexpr uint32_t SERIAL_BAUD = 1000000;
constexpr size_t BLOCK_BYTES = BLOCK_SIZE * sizeof(int32_t);

// Two application buffers allow acquisition while Serial transmits.
static int32_t audioBuffers[2][BLOCK_SIZE];
struct ReadyBlock {
  uint8_t bufferIndex;
  uint32_t sequence;
  uint32_t overflowCount;
};
static QueueHandle_t freeQueue = nullptr;
static QueueHandle_t readyQueue = nullptr;
static QueueHandle_t i2sEventQueue = nullptr;
static volatile uint32_t i2sOverflowCount = 0;

void putLE16(uint8_t *p, uint16_t x) {
  p[0] = (uint8_t)x;
  p[1] = (uint8_t)(x >> 8);
}
void putLE32(uint8_t *p, uint32_t x) {
  p[0] = (uint8_t)x;
  p[1] = (uint8_t)(x >> 8);
  p[2] = (uint8_t)(x >> 16);
  p[3] = (uint8_t)(x >> 24);
}

void writeAll(const uint8_t *p, size_t bytes) {
  size_t sent = 0;
  while (sent < bytes) {
    size_t n = Serial.write(p + sent, bytes - sent);
    sent += n;
    if (n == 0) vTaskDelay(1);
  }
}

void checkI2SEvents() {
  i2s_event_t event;
  while (xQueueReceive(i2sEventQueue, &event, 0) == pdTRUE) {
    if (event.type == I2S_EVENT_RX_Q_OVF) ++i2sOverflowCount;
  }
}

bool fillAudioBlock(int32_t *target) {
  size_t received = 0;
  while (received < BLOCK_BYTES) {
    size_t n = 0;
    esp_err_t err = i2s_read(I2S_PORT,
      reinterpret_cast<uint8_t *>(target) + received,
      BLOCK_BYTES - received, &n, portMAX_DELAY);
    if (err != ESP_OK) return false;
    received += n;
  }
  return true;
}

void acquisitionTask(void *) {
  uint32_t sequence = 0;
  while (true) {
    uint8_t index = 0;
    if (xQueueReceive(freeQueue, &index, portMAX_DELAY) != pdTRUE) continue;
    bool ok = fillAudioBlock(audioBuffers[index]);
    checkI2SEvents();
    if (!ok) {
      xQueueSend(freeQueue, &index, portMAX_DELAY);
      continue;
    }
    ReadyBlock block{index, sequence++, i2sOverflowCount};
    xQueueSend(readyQueue, &block, portMAX_DELAY);
  }
}

void transmissionTask(void *) {
  // 20-byte header: 'T2AU', sequence(u32), Fs(u32), N(u16),
  // sampleFormat(u16=1 for signed int32), I2S overflow counter(u32).
  uint8_t header[20] = {'T', '2', 'A', 'U'};
  while (true) {
    ReadyBlock block;
    if (xQueueReceive(readyQueue, &block, portMAX_DELAY) != pdTRUE) continue;
    putLE32(header + 4, block.sequence);
    putLE32(header + 8, SAMPLE_RATE);
    putLE16(header + 12, BLOCK_SIZE);
    putLE16(header + 14, FORMAT_INT32);
    putLE32(header + 16, block.overflowCount);
    writeAll(header, sizeof(header));
    writeAll(reinterpret_cast<const uint8_t *>(audioBuffers[block.bufferIndex]), BLOCK_BYTES);
    xQueueSend(freeQueue, &block.bufferIndex, portMAX_DELAY);
  }
}

void setup() {
  Serial.begin(SERIAL_BAUD);
  delay(500);

  i2s_config_t config = {};
  config.mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX);
  config.sample_rate = SAMPLE_RATE;
  config.bits_per_sample = I2S_BITS_PER_SAMPLE_32BIT;
  config.channel_format = I2S_CHANNEL_FMT_ONLY_LEFT;
  config.communication_format = I2S_COMM_FORMAT_STAND_I2S;
  config.intr_alloc_flags = 0;
  config.dma_buf_count = 8;
  config.dma_buf_len = 256;
  config.use_apll = false;

  i2s_pin_config_t pins = {};
#if ESP_IDF_VERSION_MAJOR >= 5
  pins.mck_io_num = I2S_PIN_NO_CHANGE;
#endif
  pins.bck_io_num = I2S_SCK;
  pins.ws_io_num = I2S_WS;
  pins.data_out_num = I2S_PIN_NO_CHANGE;
  pins.data_in_num = I2S_SD;

  if (i2s_driver_install(I2S_PORT, &config, 8, &i2sEventQueue) != ESP_OK) {
    while (true) delay(1000);
  }
  if (i2s_set_pin(I2S_PORT, &pins) != ESP_OK) {
    while (true) delay(1000);
  }

  freeQueue = xQueueCreate(2, sizeof(uint8_t));
  readyQueue = xQueueCreate(2, sizeof(ReadyBlock));
  if (!freeQueue || !readyQueue) while (true) delay(1000);
  uint8_t ping = 0, pong = 1;
  xQueueSend(freeQueue, &ping, portMAX_DELAY);
  xQueueSend(freeQueue, &pong, portMAX_DELAY);
  xTaskCreate(acquisitionTask, "I2S Acquisition", 4096, nullptr, 3, nullptr);
  xTaskCreate(transmissionTask, "Serial Transmission", 4096, nullptr, 2, nullptr);
}

void loop() {
  // I2S hardware/DMA controls sampling, not loop() or micros().
  vTaskDelay(pdMS_TO_TICKS(1000));
}