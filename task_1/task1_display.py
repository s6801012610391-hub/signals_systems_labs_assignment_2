import time
import serial
import numpy as np
import matplotlib.pyplot as plt

# Configuration
SERIAL_PORT = "COM3"
BAUD_RATE = 921600

SAMPLE_RATE = 10_000
BLOCK_SIZE = 1024

# แสดง Waveform ช่วง 100 ms
DISPLAY_SECONDS = 0.005
DISPLAY_SAMPLES = min(
    int(SAMPLE_RATE * DISPLAY_SECONDS),
    BLOCK_SIZE
)

ADC_MAX = 4095
ADC_VOLTAGE = 3.3

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

# เตรียมแกนเวลา หน่วย ms
time_axis_ms = (
    np.arange(DISPLAY_SAMPLES)
    / SAMPLE_RATE
    * 1000
)

# เตรียม FFT
frequency_axis = np.fft.rfftfreq(
    BLOCK_SIZE,
    d=1 / SAMPLE_RATE
)

hann_window = np.hanning(
    BLOCK_SIZE
)

window_gain = np.mean(
    hann_window
)

# สร้างกราฟ
plt.ion()

figure, axes = plt.subplots(
    2,
    1,
    figsize=(10, 7)
)

figure.canvas.manager.set_window_title(
    "ESP32 Waveform and FFT"
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
    "Amplitude (V)"
)

axes[0].set_xlim(
    0,
    time_axis_ms[-1]
)

axes[0].set_ylim(
    -2.5,
    2.5
)

axes[0].grid(True)

# กราฟ FFT
fft_line, = axes[1].plot(
    frequency_axis,
    np.zeros(len(frequency_axis)),
    color="red",
    linewidth=1.5
)

axes[1].set_title(
    "FFT Magnitude Spectrum"
)

axes[1].set_xlabel(
    "Frequency (Hz)"
)

axes[1].set_ylabel(
    "Magnitude (V)"
)

axes[1].set_xlim(
    0,
    SAMPLE_RATE / 2
)

axes[1].set_ylim(
    0,
    0.7
)

axes[1].grid(True)

plt.tight_layout()
plt.show(block=False)
plt.pause(0.1)

# Buffer รับข้อมูล
serial_data = bytearray()

# uint16 จำนวน 1024 ค่า ค่าใดละ 2 bytes
required_bytes = BLOCK_SIZE * 2

# Real-time Loop
try:
    while plt.fignum_exists(figure.number):

        # อ่านข้อมูลทั้งหมดที่มีใน Serial
        available = esp32.in_waiting

        if available > 0:
            serial_data.extend(
                esp32.read(available)
            )
        else:
            plt.pause(0.001)
            continue

        # รอข้อมูลให้ครบ 1024 Samples
        if len(serial_data) < required_bytes:
            plt.pause(0.001)
            continue

        # ใช้ข้อมูล Block ล่าสุด ลด Delay สะสม
        complete_bytes = (
            len(serial_data)
            - (len(serial_data) % 2)
        )

        start = (
            complete_bytes
            - required_bytes
        )

        block = bytes(
            serial_data[
                start:start + required_bytes
            ]
        )

        # ลบข้อมูลเก่าที่อ่านแล้ว
        del serial_data[
            :start + required_bytes
        ]

        # แปลงข้อมูล uint16 แบบ Little Endian
        adc_samples = np.frombuffer(
            block,
            dtype="<u2"
        ).copy()

        # ใช้เฉพาะข้อมูล ADC 12-bit
        adc_samples = (
            adc_samples & 0x0FFF
        ).astype(np.float64)

        # แปลงค่า ADC เป็นแรงดัน
        voltage = (
            adc_samples
            * ADC_VOLTAGE
            / ADC_MAX
        )

        # ลบ DC Offset สำหรับคำนวณ FFT
        dc_offset = np.mean(
            voltage
        )

        signal = (
            voltage - dc_offset
        )

        # คำนวณ RMS และ Vpp
        rms_value = np.sqrt(
            np.mean(signal ** 2)
        )

        peak_to_peak = (
            np.max(signal)
            - np.min(signal)
        )

        # คำนวณ FFT จาก 1024 Samples
        windowed_signal = (
            signal * hann_window
        )

        fft_result = np.fft.rfft(
            windowed_signal
        )

        fft_magnitude = (
            np.abs(fft_result)
            / (BLOCK_SIZE * window_gain)
        )

        # ทำเป็น Single-sided FFT
        fft_magnitude[1:-1] *= 2

        # หาความถี่หลัก โดยไม่รวม DC
        peak_index = (
            np.argmax(
                fft_magnitude[1:]
            )
            + 1
        )

        dominant_frequency = (
            frequency_axis[peak_index]
        )

        display_signal = signal[:DISPLAY_SAMPLES]

        waveform_line.set_ydata(
            display_signal
        )

        axes[0].set_title(
            f"Waveform | "
            f"DC={dc_offset:.3f} V | "
            f"RMS={rms_value:.4f} V | "
            f"Vpp={peak_to_peak:.4f} V"
        )

        # อัปเดต FFT
        fft_line.set_ydata(
            fft_magnitude
        )

        axes[1].set_title(
            f"FFT | Dominant Frequency = "
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
