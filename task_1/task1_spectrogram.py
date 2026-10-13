import time
import serial
import numpy as np
import matplotlib.pyplot as plt

# Configuration
SERIAL_PORT = "COM3"
BAUD_RATE = 921600

SAMPLE_RATE = 10_000
FFT_SIZE = 1024

ADC_MAX = 4095
ADC_VOLTAGE = 3.3

# Waveform แสดงย้อนหลัง 1 วินาที
WAVEFORM_SECONDS = 1
WAVEFORM_SAMPLES = (
    SAMPLE_RATE * WAVEFORM_SECONDS
)

# Spectrogram เก็บ 50 FFT blocks
SPECTROGRAM_COLUMNS = 50

# ระยะเวลาของ Spectrogram
SPECTROGRAM_SECONDS = (
    SPECTROGRAM_COLUMNS
    * FFT_SIZE
    / SAMPLE_RATE
)

# เปิด Serial Port
try:
    esp32 = serial.Serial(
        port=SERIAL_PORT,
        baudrate=BAUD_RATE,
        timeout=0.1
    )

except serial.SerialException as error:
    print("Cannot open", SERIAL_PORT)
    print(error)
    print("ปิด Arduino Serial Monitor และ Python ตัวเก่าก่อน")
    raise SystemExit

print("Connected to", SERIAL_PORT)
print("Waiting for ESP32...")

time.sleep(2)
esp32.reset_input_buffer()

print("Receiving ADC data...")
print("Press Ctrl+C to stop")

# เตรียมข้อมูล
required_bytes = FFT_SIZE * 2
serial_data = bytearray()

# ใช้ตรวจว่า uint16 เริ่มตรง Byte หรือไม่
serial_synchronized = False

# Waveform ย้อนหลัง 1 วินาที
waveform_history = np.zeros(
    WAVEFORM_SAMPLES
)

waveform_time = np.linspace(
    -WAVEFORM_SECONDS,
    0,
    WAVEFORM_SAMPLES
)

# Hann Window
hann_window = np.hanning(
    FFT_SIZE
)

hann_gain = np.mean(
    hann_window
)

# แกนความถี่
frequency_axis = np.fft.rfftfreq(
    FFT_SIZE,
    d=1 / SAMPLE_RATE
)

# ข้อมูล Spectrogram เริ่มต้น
spectrogram_data = np.full(
    (
        len(frequency_axis),
        SPECTROGRAM_COLUMNS
    ),
    -100.0
)

# สร้างกราฟ
plt.ion()

figure, axes = plt.subplots(
    2,
    1,
    figsize=(11, 8)
)

figure.canvas.manager.set_window_title(
    "ESP32 Real-Time Spectrogram"
)

# กราฟ Waveform
waveform_line, = axes[0].plot(
    waveform_time,
    waveform_history,
    color="blue",
    linewidth=1
)

axes[0].set_title(
    "Time-Series Audio Waveform"
)

axes[0].set_xlabel(
    "Time (s)"
)

axes[0].set_ylabel(
    "Amplitude (V)"
)

axes[0].set_xlim(
    -WAVEFORM_SECONDS,
    0
)

# ถ้าเสียงเล็กมาก เปลี่ยนเป็น -0.1, 0.1
axes[0].set_ylim(
    -0.5,
    0.5
)

axes[0].grid(True)

# กราฟ Spectrogram
spectrogram_image = axes[1].imshow(
    spectrogram_data,
    origin="lower",
    aspect="auto",
    extent=[
        -SPECTROGRAM_SECONDS,
        0,
        0,
        SAMPLE_RATE / 2
    ],
    cmap="viridis",
    vmin=-80,
    vmax=0
)

axes[1].set_title(
    "Real-Time Spectrogram"
)

axes[1].set_xlabel(
    "Time (s)"
)

axes[1].set_ylabel(
    "Frequency (Hz)"
)

axes[1].set_ylim(
    0,
    SAMPLE_RATE / 2
)

colorbar = figure.colorbar(
    spectrogram_image,
    ax=axes[1]
)

colorbar.set_label(
    "Magnitude (dBV)"
)

plt.tight_layout()
plt.show(block=False)
plt.pause(0.1)


# Real-time Loop
try:
    while plt.fignum_exists(figure.number):

        # อ่านข้อมูลจาก Serial
        available = esp32.in_waiting

        if available > 0:
            serial_data.extend(
                esp32.read(available)
            )
        else:
            plt.pause(0.001)
            continue

        # ตรวจสอบตำแหน่ง uint16 ครั้งแรก
        if not serial_synchronized:

            if len(serial_data) < required_bytes + 1:
                plt.pause(0.001)
                continue

            test_data = bytes(
                serial_data[
                    :required_bytes + 1
                ]
            )

            offset_0 = np.frombuffer(
                test_data[:required_bytes],
                dtype="<u2"
            )

            offset_1 = np.frombuffer(
                test_data[1:required_bytes + 1],
                dtype="<u2"
            )

            score_0 = np.mean(
                offset_0 <= ADC_MAX
            )

            score_1 = np.mean(
                offset_1 <= ADC_MAX
            )

            if score_1 > score_0:
                del serial_data[0]

            serial_synchronized = True

            print("Serial data synchronized")

        # รอข้อมูลครบ 1024 Samples
        if len(serial_data) < required_bytes:
            plt.pause(0.001)
            continue


        # ถ้าข้อมูลสะสมมาก ให้ทิ้ง Block เก่า
        while len(serial_data) >= required_bytes * 3:
            del serial_data[:required_bytes]

        block = bytes(
            serial_data[:required_bytes]
        )

        del serial_data[:required_bytes]

        # แปลงข้อมูล ADC
        adc_samples = np.frombuffer(
            block,
            dtype="<u2"
        ).astype(np.float64)

        # ตรวจสอบความถูกต้อง
        if np.mean(adc_samples <= ADC_MAX) < 0.95:
            print("Serial alignment lost")

            serial_data.clear()
            serial_synchronized = False
            continue

        # แปลงเป็นแรงดัน
        voltage = (
            adc_samples
            * ADC_VOLTAGE
            / ADC_MAX
        )

        # ลบ DC Offset
        dc_offset = np.mean(
            voltage
        )

        audio_signal = (
            voltage - dc_offset
        )

        # อัปเดต Waveform History
        waveform_history = np.roll(
            waveform_history,
            -FFT_SIZE
        )

        waveform_history[-FFT_SIZE:] = (
            audio_signal
        )

        waveform_line.set_ydata(
            waveform_history
        )
        # คำนวณ FFT สำหรับ Spectrogram
        windowed_signal = (
            audio_signal * hann_window
        )

        fft_result = np.fft.rfft(
            windowed_signal
        )

        fft_magnitude = (
            np.abs(fft_result)
            / (FFT_SIZE * hann_gain)
        )

        fft_magnitude[1:-1] *= 2

        # แปลงเป็น dBV
        fft_db = 20 * np.log10(
            fft_magnitude + 1e-12
        )

        # อัปเดต Spectrogram
        spectrogram_data[:, :-1] = (
            spectrogram_data[:, 1:]
        )

        spectrogram_data[:, -1] = (
            fft_db
        )

        spectrogram_image.set_data(
            spectrogram_data
        )

        # หาความถี่เด่น
        peak_index = (
            np.argmax(fft_magnitude[1:])
            + 1
        )

        dominant_frequency = (
            frequency_axis[peak_index]
        )

        axes[1].set_title(
            f"Real-Time Spectrogram | "
            f"Dominant Frequency = "
            f"{dominant_frequency:.2f} Hz"
        )

        # วาดกราฟ
        figure.canvas.draw_idle()
        figure.canvas.flush_events()
        plt.pause(0.001)
except KeyboardInterrupt:
    print()
    print("Stopped by user")

finally:
    if esp32.is_open:
        esp32.close()
    plt.ioff()
    plt.close("all")
    print("Serial port closed")
