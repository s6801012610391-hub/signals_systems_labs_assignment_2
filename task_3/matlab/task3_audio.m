function task3_audio(portName)
% FPGA audio + FFT + CRC-32 + Save As PNG
% Run: task3_audio("COM3")

if nargin < 1
    portName = "COM3";
end

%% การตั้งค่า
baud = 921600;
expectedFs = 16000;
expectedN = 1024;
useHann = true;

% แกนสำหรับทดสอบsin1khz
waveTimeLimit = [0 13];       % ms
waveAmplitudeLimit = [500 2000];

fftFrequencyLimit = [0 5000]; % Hz
fftAmplitudeLimit = [0 150];

% ใช้ [] หากต้องการแกนตั้งอัตโนมัติ
% waveAmplitudeLimit = [];
% fftAmplitudeLimit = [];

saveFolder = fullfile( ...
    fileparts(mfilename("fullpath")), "task3_images");

assert( ...
    crc32IEEE(uint8('123456789')) == ...
    uint32(hex2dec('CBF43926')), ...
    'CRC-32 reference check failed.');

%% เปิด Serial
s = serialport(portName, baud, "Timeout", 1);
serialCleanup = onCleanup(@() delete(s)); %#ok<NASGU>
flush(s, "input");

%% หน้าต่างกราฟ
fig = figure( ...
    "Name", "Task 3: FPGA Audio + CRC-32", ...
    "NumberTitle", "off", ...
    "Color", "white", ...
    "Units", "pixels", ...
    "Position", [100 80 1100 720]);

%% Waveform
ax1 = axes( ...
    "Parent", fig, ...
    "Units", "normalized", ...
    "Position", [0.10 0.59 0.86 0.28]);

waveLine = plot(ax1, nan, nan, "b-");

grid(ax1, "on");
xlabel(ax1, "Time within block (ms)");
ylabel(ax1, "Sample value (counts)");

title(ax1, "Waiting for T3AC data...", ...
    "FontSize", 10, "Interpreter", "none");

xlim(ax1, waveTimeLimit);

if isempty(waveAmplitudeLimit)
    ylim(ax1, "auto");
else
    ylim(ax1, waveAmplitudeLimit);
end

%% FFT
ax2 = axes( ...
    "Parent", fig, ...
    "Units", "normalized", ...
    "Position", [0.10 0.13 0.86 0.30]);

fftLine = plot(ax2, nan, nan, "r-");

grid(ax2, "on");
xlabel(ax2, "Frequency (Hz)");
ylabel(ax2, "Amplitude (counts)");

xlim(ax2, fftFrequencyLimit);
xticks(ax2, fftFrequencyLimit(1):500:fftFrequencyLimit(2));

if isempty(fftAmplitudeLimit)
    ylim(ax2, "auto");
else
    ylim(ax2, fftAmplitudeLimit);
end

if useHann
    windowName = "Hann";
else
    windowName = "Rectangular";
end

title(ax2, {
    sprintf("FFT (%s), mean removed", windowName)
    "CRC errors: 0 | bad headers: 0 | invalid samples: 0"
}, "FontSize", 10, "Interpreter", "none");

%% ปุ่ม Save PNG
uicontrol(fig, ...
    "Style", "pushbutton", ...
    "String", "Save PNG", ...
    "Units", "normalized", ...
    "Position", [0.83 0.945 0.14 0.045], ...
    "FontSize", 11, ...
    "FontWeight", "bold", ...
    "Interruptible", "off", ...
    "BusyAction", "cancel", ...
    "Callback", @(btn, ~) saveTask3PNG( ...
        fig, btn, saveFolder, ax1, ax2));

%% ตัวนับและบัฟเฟอร์
buffer = uint8([]);
latest = [];
lastSeq = [];

received = 0;
gapEstimate = 0;
duplicates = 0;
backwardEvents = 0;
crcErrors = 0;
rejectedHeaders = 0;
invalidSamples = 0;

clockStart = tic;
lastPlot = -inf;

%% รับข้อมูล
while isgraphics(fig)

    available = s.NumBytesAvailable;

    if available > 0
        bytes = uint8(read( ...
            s, min(available, 65536), "uint8"));

        buffer = [buffer reshape(bytes, 1, [])]; %#ok<AGROW>
    end

    while true
        [packet, buffer, badHeader, badCRC, badSamples] = ...
            takePacket(buffer, expectedFs, expectedN);

        rejectedHeaders = rejectedHeaders + badHeader;
        crcErrors = crcErrors + badCRC;
        invalidSamples = invalidSamples + badSamples;

        if isempty(packet)
            break;
        end

        received = received + 1;

        if ~isempty(lastSeq)
            delta = mod(packet.seq - lastSeq, 2^32);

            if delta == 0
                duplicates = duplicates + 1;
            elseif delta < 2^31
                gapEstimate = gapEstimate + delta - 1;
            else
                backwardEvents = backwardEvents + 1;
            end
        end

        lastSeq = packet.seq;
        latest = packet;
    end

    %% อัปเดตกราฟ
    if toc(clockStart) - lastPlot >= 0.05

        if ~isempty(latest)
            x = latest.samples;
            n = numel(x);
            t = (0:n-1) / latest.fs * 1000;

            ac = x - mean(x);

            if useHann
                w = 0.5 - 0.5 * cos(2*pi*(0:n-1)/n);
            else
                w = ones(1, n);
            end

            y = fft(ac .* w);
            amplitude = abs(y(1:n/2+1)) / sum(w);
            amplitude(2:end-1) = 2 * amplitude(2:end-1);
            frequency = (0:n/2) * latest.fs / n;

            set(waveLine, "XData", t, "YData", x);
            set(fftLine, ...
                "XData", frequency, "YData", amplitude);

            title(ax1, {
                sprintf( ...
                    "Fs (header): %g Hz | N: %d | valid: %d", ...
                    latest.fs, n, received)
                sprintf( ...
                    "gap estimate: %d | duplicate: %d | backward/ambiguous: %d", ...
                    gapEstimate, duplicates, backwardEvents)
            }, "FontSize", 10, "Interpreter", "none");

            latest = [];
        end

        title(ax2, {
            sprintf("FFT (%s), mean removed", windowName)
            sprintf( ...
                "CRC errors: %d | bad headers: %d | invalid samples: %d", ...
                crcErrors, rejectedHeaders, invalidSamples)
        }, "FontSize", 10, "Interpreter", "none");

        lastPlot = toc(clockStart);
    end

    drawnow limitrate;
    pause(0.002);
end

fprintf( ...
    ['Stopped. Valid=%d, gap estimate=%d, duplicates=%d, ' ...
     'backward/ambiguous=%d, CRC errors=%d, invalid samples=%d\n'], ...
    received, gapEstimate, duplicates, ...
    backwardEvents, crcErrors, invalidSamples);

end


%% ตรวจและแยกแพ็กเก็ต
function [packet, buffer, badHeader, badCRC, badSamples] = ...
    takePacket(buffer, expectedFs, expectedN)

packet = [];
badHeader = 0;
badCRC = 0;
badSamples = 0;

while numel(buffer) >= 4

    markers = strfind(char(buffer), 'T3AC');

    if isempty(markers)
        buffer = buffer(max(1, numel(buffer)-2):end);
        return;
    end

    buffer = buffer(markers(1):end);

    if numel(buffer) < 16
        return;
    end

    fs = littleEndian(buffer(5:8));
    n = littleEndian(buffer(9:10));
    format = littleEndian(buffer(11:12));
    seq = littleEndian(buffer(13:16));

    if fs ~= expectedFs || ...
       n ~= expectedN || ...
       ~ismember(format, [1 2])

        buffer = buffer(2:end);
        badHeader = badHeader + 1;
        continue;
    end

    dataBytes = 16 + 2*n;
    packetBytes = dataBytes + 4;

    if numel(buffer) < packetBytes
        return;
    end

    receivedCRC = uint32(littleEndian( ...
        buffer(dataBytes+1:packetBytes)));

    calculatedCRC = crc32IEEE(buffer(1:dataBytes));

    if receivedCRC ~= calculatedCRC
        badCRC = badCRC + 1;
        buffer = buffer(2:end);
        continue;
    end

    payload = buffer(17:dataBytes);

    values = double(payload(1:2:end)) + ...
             256 * double(payload(2:2:end));

    if format == 1
        if any(values > 4095)
            buffer = buffer(packetBytes+1:end);
            badSamples = badSamples + 1;
            continue;
        end
    else
        negative = values >= 32768;
        values(negative) = values(negative) - 65536;
    end

    packet = struct( ...
        "fs", fs, ...
        "seq", seq, ...
        "samples", values);

    buffer = buffer(packetBytes+1:end);
    return;
end

end


%% Little-endian
function value = littleEndian(bytes)

bytes = reshape(bytes, 1, []);
value = sum(double(bytes) .* ...
    (256 .^ (0:numel(bytes)-1)));

end


%% CRC-32/ISO-HDLC
function crc = crc32IEEE(bytes)

persistent crcTable

if isempty(crcTable)
    crcTable = zeros(1, 256, 'uint32');
    polynomial = uint32(hex2dec('EDB88320'));

    for k = 0:255
        c = uint32(k);

        for bitIndex = 1:8
            if bitand(c, uint32(1)) ~= 0
                c = bitxor(bitshift(c, -1), polynomial);
            else
                c = bitshift(c, -1);
            end
        end

        crcTable(k+1) = c;
    end
end

crc = uint32(hex2dec('FFFFFFFF'));
bytes = reshape(uint8(bytes), 1, []);

for b = bytes
    index = double(bitand( ...
        bitxor(crc, uint32(b)), uint32(255))) + 1;

    crc = bitxor(bitshift(crc, -8), crcTable(index));
end

crc = bitxor(crc, uint32(hex2dec('FFFFFFFF')));

end


%% Save PNG พร้อมหน้าต่างเลือกชื่อและโฟลเดอร์
function saveTask3PNG(fig, btn, saveFolder, ax1, ax2)

if ~isgraphics(fig) || ~isgraphics(btn) || ...
   ~isgraphics(ax1) || ~isgraphics(ax2)
    return;
end

set(btn, "Enable", "off", "String", "Save As...");

buttonCleanup = onCleanup( ...
    @() restoreTask3SaveButton(btn)); %#ok<NASGU>

try
    % คัดลอกกราฟ ณ ตอนกดปุ่ม
    exportFig = figure( ...
        "Visible", "off", ...
        "WindowStyle", "normal", ...
        "Color", "white", ...
        "Units", "pixels", ...
        "Position", [100 80 1100 720], ...
        "PaperPositionMode", "auto");

    figureCleanup = onCleanup( ...
        @() deleteTask3ExportFigure(exportFig)); %#ok<NASGU>

    exportAx1 = copyobj(ax1, exportFig);
    exportAx2 = copyobj(ax2, exportFig);

    set(exportAx1, ...
        "Units", "normalized", ...
        "Position", [0.10 0.59 0.86 0.28]);

    set(exportAx2, ...
        "Units", "normalized", ...
        "Position", [0.10 0.13 0.86 0.30]);

    title(exportAx1, ax1.Title.String, ...
        "FontSize", 10, "Interpreter", "none");

    title(exportAx2, ax2.Title.String, ...
        "FontSize", 10, "Interpreter", "none");

    if ~isfolder(saveFolder)
        mkdir(saveFolder);
    end

    stamp = char(datetime("now", ...
        "Format", "yyyyMMdd_HHmmss_SSS"));

    defaultName = fullfile(saveFolder, ...
        ["task3_" stamp ".png"]);

    % เปิดหน้าต่าง Save As
    figure(fig);

    [file, folder] = uiputfile( ...
        {'*.png', 'PNG image (*.png)'}, ...
        'Save Task 3 waveform and FFT', ...
        defaultName);

    % ผู้ใช้กด Cancel
    if isequal(file, 0) || isequal(folder, 0)
        return;
    end

    fileName = fullfile(folder, file);

    % ใช้ PNG เท่านั้น
    [~, ~, extension] = fileparts(fileName);

    if isempty(extension)
        fileName = [fileName '.png'];
    elseif ~strcmpi(extension, '.png')
        error("Task3:PNGOnly", ...
            "Please use a filename ending in .png");
    end

    if isgraphics(btn)
        set(btn, "String", "Saving...");
    end

    try
        exportgraphics(exportFig, fileName, ...
            "Resolution", 200, ...
            "BackgroundColor", "white");
    catch
        print(exportFig, fileName, "-dpng", "-r200");
    end

    fprintf("Saved PNG: %s\n", fileName);

catch err
    warning("Task3:SavePNG", ...
        "Cannot save PNG: %s", err.message);
end

end


%% คืนสถานะปุ่ม
function restoreTask3SaveButton(btn)

if isgraphics(btn)
    set(btn, "Enable", "on", "String", "Save PNG");
end

end


%% ลบหน้าต่างสำเนา
function deleteTask3ExportFigure(fig)

if isgraphics(fig)
    delete(fig);
end

end