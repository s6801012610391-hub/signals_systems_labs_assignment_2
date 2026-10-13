clc;
clear;
close all;

%% =========================================
% TASK 2: REAL-TIME AUDIO SAMPLING
% ESP32 + INMP441 + MATLAB
% No Signal Processing Toolbox required
%% =========================================

%% 1. SETTINGS
port = "COM3";          % ESP32 COM Port
baud = 921600;          % Serial Baud Rate

Fs = 16000;             % Sampling Rate = 16 kHz
N = 1024;               % Samples per block

plotEvery = 4;          % Update graphs every 4 blocks
historySize = 4096;     % Audio history samples

%% 2. CONNECT ESP32
s = serialport(port, baud);
s.Timeout = 5;
s.ByteOrder = "little-endian";

pause(2);
flush(s);

disp("ESP32 Connected!");
disp("Receiving audio data...");

%% 3. CREATE TIME AND FREQUENCY AXES
t = (0:N-1) / Fs;
f = (0:N/2) * Fs/N;

audioHistory = zeros(historySize, 1);

% Create Hann Window manually
n = (0:N-1)';
w = 0.5 - 0.5*cos(2*pi*n/(N-1));

%% 4. CREATE SPECTROGRAM SETTINGS
winSize = 256;
overlap = 192;
hop = winSize - overlap;
nfft = 512;

% Manual Hann Window
n2 = (0:winSize-1)';
w256 = 0.5 - 0.5*cos(2*pi*n2/(winSize-1));

% Number of spectrogram frames
numFrames = floor((historySize-winSize)/hop) + 1;

% Spectrogram axes
specF = (0:nfft/2) * Fs/nfft;
specT = ((0:numFrames-1)*hop + winSize/2)/Fs;

% Empty spectrogram
specData = -120 * ones(nfft/2+1, numFrames);

%% 5. CREATE FIGURE
fig = figure('Name', ...
    'Task 2 - Real-Time Audio Sampling', ...
    'NumberTitle', 'off');

%% WAVEFORM
ax1 = subplot(3,1,1);

h1 = plot(ax1, t, zeros(1,N), 'b');

title('Real-Time Audio Waveform');
xlabel('Time (s)');
ylabel('Amplitude');

xlim([0 N/Fs]);
ylim([-1 1]);
grid on;

%% FFT SPECTRUM
ax2 = subplot(3,1,2);

h2 = plot(ax2, f, zeros(size(f)), 'r');

title('Real-Time FFT Spectrum');
xlabel('Frequency (Hz)');
ylabel('Magnitude');

xlim([0 Fs/2]);
ylim([0 1]);
grid on;

%% SPECTROGRAM
ax3 = subplot(3,1,3);

h3 = imagesc(ax3, specT, specF, specData);

axis(ax3, 'xy');

title('Real-Time Spectrogram');
xlabel('Time (s)');
ylabel('Frequency (Hz)');

ylim([0 Fs/2]);

colormap(ax3, 'turbo');
colorbar(ax3);

clim(ax3, [-120 0]);

%% 6. REAL-TIME AUDIO LOOP
%% SAVE GRAPH BUTTON

uicontrol('Parent', fig, ...
    'Style', 'pushbutton', ...
    'String', 'Save PNG', ...
    'Units', 'normalized', ...
    'Position', [0.85 0.95 0.12 0.04], ...
    'FontSize', 10, ...
    'Callback', @(src,event) saveGraph(fig));

%% SAVE FUNCTION
% Put this function at the very end of the .m file


blockCount = 0;

try
    while isgraphics(fig)

        % Read 1024 samples from ESP32
        raw = read(s, N, "int32");

        if numel(raw) ~= N
            continue;
        end

        % Convert raw samples to double
        x = double(raw(:)) / 2^31;

        % Remove DC offset
        x = x - mean(x);

        % Update audio history
        audioHistory = ...
            [audioHistory(N+1:end); x];

        blockCount = blockCount + 1;

        % Update graph every 4 blocks
        if mod(blockCount, plotEvery) ~= 0
            continue;
        end


        %% 7. UPDATE WAVEFORM

        set(h1, ...
            'XData', t, ...
            'YData', x);

        % Fixed amplitude scale
        ylim(ax1, [-1 1]);


        %% 8. CALCULATE FFT
        X = fft(x .* w);

        magnitude = abs(X(1:N/2+1))*2/sum(w);

        magnitude(1) = magnitude(1)/2;
        magnitude(end) = magnitude(end)/2;

        set(h2, ...
            'XData', f, ...
            'YData', magnitude);

        % Automatic FFT magnitude scale
        peak = max(magnitude);

        if peak < 0.001
            peak = 0.001;
        end

        ylim(ax2, [0 peak*1.2]);

        %% 9. CALCULATE SPECTROGRAM MANUALLY
        for k = 1:numFrames

            % Frame start and end
            startIdx = (k-1)*hop + 1;
            endIdx = startIdx + winSize - 1;

            % Select audio segment
            segment = audioHistory(startIdx:endIdx);

            % Apply Hann Window
            segment = segment .* w256;

            % Calculate FFT
            S = fft(segment, nfft);

            % Positive frequencies
            S = S(1:nfft/2+1);

            % Convert magnitude to dB
            specData(:,k) = ...
                20*log10(abs(S)/sum(w256) + 1e-12);

        end

        %% 10. UPDATE SPECTROGRAM
        set(h3, ...
            'XData', specT, ...
            'YData', specF, ...
            'CData', specData);

        % Refresh graphs
        drawnow limitrate;

    end

catch ME
    disp("Error: " + ME.message);
end

%% 11. DISCONNECT ESP32
clear s;

disp("Serial connection closed.");


function saveGraph(fig)

[file, path] = uiputfile( ...
    '*.png', 'Save Task 2 Graph', ...
    'Task2_Results.png');

if isequal(file, 0)
    return;
end

exportgraphics(fig, fullfile(path, file), ...
    'Resolution', 300);

disp("Graph saved successfully!");

end