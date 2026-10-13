import time
import serial
import numpy as np
import matplotlib.pyplot as plt

# Configuration
SERIAL_PORT = "COM3"
BAUD_RATE = 921600

SAMPLE_RATE = 10000
BLOCK_SIZE = 1024

DISPLAY_SECONDS = 0.005
DISPLAY_SAMPLES = int(
    SAMPLE_RATE * DISPLAY_SECONDS
)

ADC_MAX = 4095
ADC_VOLTAGE = 3.3

# แสดง FFT ช่วง 0–2000 Hz เพื่อให้เห็น 1 kHz ชัด
FFT_MAX_FREQUENCY = 2000

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
    print("ปิด Serial Monitor และ Python ตัวเก่าก่อน")
    raise SystemExit

print("Connected to", SERIAL_PORT)
print("Waiting for ESP32...")

time.sleep(2)
esp32.reset_input_buffer()

print("Receiving ADC data...")
print("Press Ctrl+C to stop")

# เตรียมแกนเวลาและความถี่
time_axis_ms = (
    np.arange(DISPLAY_SAMPLES)
    / SAMPLE_RATE
    * 1000
)

frequency_axis = np.fft.rfftfreq(
    BLOCK_SIZE,
    d=1 / SAMPLE_RATE
)

frequency_resolution = (
    SAMPLE_RATE / BLOCK_SIZE
)

print(
    "FFT frequency resolution:",
    frequency_resolution,
    "Hz"
)


# สร้าง Hann Window
hann_window = np.hanning(
    BLOCK_SIZE
)

# ใช้ชดเชยขนาดสัญญาณที่ลดลงจาก Window
hann_coherent_gain = np.mean(
    hann_window
)

# สร้างกราฟ
plt.ion()

figure, axes = plt.subplots(
    3,
    1,
    figsize=(11, 9)
)

figure.canvas.manager.set_window_title(
    "FFT Windowing Comparison"
)

# กราฟ Time Domain
waveform_line, = axes[0].plot(
    time_axis_ms,
    np.zeros(DISPLAY_SAMPLES),
    color="blue",
    linewidth=1.5
)

axes[0].set_title(
    "Time-Domain Waveform"
)

axes[0].set_xlabel(
    "Time (ms)"
)

axes[0].set_ylabel(
    "Voltage (V)"
)

axes[0].set_xlim(
    0,
    time_axis_ms[-1]
)

axes[0].set_ylim(
    0,
    3.3
)

axes[0].grid(True)

# FFT ไม่ใช้ Window
fft_no_window_line, = axes[1].plot(
    frequency_axis,
    np.zeros(len(frequency_axis)),
    color="orange",
    linewidth=1.2
)

axes[1].set_title(
    "FFT Without Window"
)

axes[1].set_xlabel(
    "Frequency (Hz)"
)

axes[1].set_ylabel(
    "Magnitude (V)"
)

axes[1].set_xlim(
    0,
    FFT_MAX_FREQUENCY
)

axes[1].set_ylim(
    0,
    0.7
)

axes[1].grid(True)

# FFT ใช้ Hann Window
fft_hann_line, = axes[2].plot(
    frequency_axis,
    np.zeros(len(frequency_axis)),
    color="red",
    linewidth=1.2
)

axes[2].set_title(
    "FFT With Hann Window"
)

axes[2].set_xlabel(
    "Frequency (Hz)"
)

axes[2].set_ylabel(
    "Magnitude (V)"
)

axes[2].set_xlim(
    0,
    FFT_MAX_FREQUENCY
)

axes[2].set_ylim(
    0,
    0.7
)

axes[2].grid(True)

plt.tight_layout()
plt.show(block=False)
plt.pause(0.1)

# Serial Buffer
serial_data = bytearray()

required_bytes = BLOCK_SIZE * 2

# Real-time Loop
try:
    while plt.fignum_exists(figure.number):

        available = esp32.in_waiting

        if available > 0:
            serial_data.extend(
                esp32.read(available)
            )
        else:
            plt.pause(0.001)
            continue

        # อ่านเพิ่ม 1 Byte เพื่อใช้ตรวจสอบตำแหน่ง uint16
        if len(serial_data) < required_bytes + 1:
            plt.pause(0.001)
            continue

        # เลือกข้อมูลล่าสุด ลด Delay
        raw_block = bytes(
            serial_data[
                -(required_bytes + 1):
            ]
        )

        serial_data.clear()

        # ตรวจสอบ Byte Alignment
        samples_offset_0 = np.frombuffer(
            raw_block[:required_bytes],
            dtype="<u2"
        ).copy()

        samples_offset_1 = np.frombuffer(
            raw_block[1:required_bytes + 1],
            dtype="<u2"
        ).copy()

        score_0 = np.mean(
            samples_offset_0 <= ADC_MAX
        )

        score_1 = np.mean(
            samples_offset_1 <= ADC_MAX
        )

        if score_0 >= score_1:
            adc_samples = samples_offset_0
        else:
            adc_samples = samples_offset_1

        adc_samples = adc_samples.astype(
            np.float64
        )

        # แปลง ADC เป็นแรงดัน
        voltage = (
            adc_samples
            * ADC_VOLTAGE
            / ADC_MAX
        )

        # ลบ DC Offset
        dc_offset = np.mean(
            voltage
        )

        signal = (
            voltage - dc_offset
        )

        # FFT แบบไม่ใช้ Window
        fft_no_window = np.fft.rfft(
            signal
        )

        magnitude_no_window = (
            np.abs(fft_no_window)
            / BLOCK_SIZE
        )

        # Single-sided spectrum
        magnitude_no_window[1:-1] *= 2

        # FFT แบบใช้ Hann Window
        windowed_signal = (
            signal * hann_window
        )

        fft_hann = np.fft.rfft(
            windowed_signal
        )

        magnitude_hann = (
            np.abs(fft_hann)
            / (
                BLOCK_SIZE
                * hann_coherent_gain
            )
        )

        # Single-sided spectrum
        magnitude_hann[1:-1] *= 2

        # หาความถี่เด่น
        peak_no_window = (
            np.argmax(
                magnitude_no_window[1:]
            )
            + 1
        )

        peak_hann = (
            np.argmax(
                magnitude_hann[1:]
            )
            + 1
        )

        dominant_no_window = (
            frequency_axis[peak_no_window]
        )

        dominant_hann = (
            frequency_axis[peak_hann]
        )

        # อัปเดตกราฟ
        waveform_line.set_ydata(
            voltage[:DISPLAY_SAMPLES]
        )

        axes[0].set_title(
            f"Time-Domain Waveform | "
            f"DC = {dc_offset:.3f} V"
        )

        fft_no_window_line.set_ydata(
            magnitude_no_window
        )

        axes[1].set_title(
            f"FFT Without Window | "
            f"Dominant = {dominant_no_window:.2f} Hz"
        )

        fft_hann_line.set_ydata(
            magnitude_hann
        )

        axes[2].set_title(
            f"FFT With Hann Window | "
            f"Dominant = {dominant_hann:.2f} Hz"
        )

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
