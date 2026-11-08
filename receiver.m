% RECEIVER 
%
% This is the receiver structure that you will have to complete.
% The function: receiver(fc) is a setup function for the receiver. Here,
% the audiorecorder object is initialized (see help audiorecorder or
% MATLAB's homepage for more information about the object).
% 
% The callback function audioTimerFcn() is a callback function that is
% triggered on a specified time interval (here it is determined in the
% setup function, by the variable time_value)
% 
% Your task is to extend this code to work in the project!
%%

function [audio_recorder] = receiver(fc)

%-----------------------------------------------------------
% variable defination

fs = 15000;                                             % sampling frequency
audio_recorder = audiorecorder(fs,24,1);                % create the recorder
audio_recorder.UserData.fc = fc;
audio_recorder.UserData.fs = fs;
%------------------------------------------------------------

%attach callback function
time_value = 2; % how often the function should be called in seconds
set(audio_recorder,'TimerPeriod',time_value,'TimerFcn',@audioTimerFcn); % attach a function that should be called every second, the function that is called is specified below.

%ADD USER DATA FOR CALLBACK FUNCTION (DO NOT CHANGE THE NAMES OF THESE VARIABLES!)
audio_recorder.UserData.receive_complete = 0; % this is a flag that the while loop in the GUI will check
audio_recorder.UserData.pack  = []; %allocate for data package
audio_recorder.UserData.pwr_spect = []; %allocate for PSD
audio_recorder.UserData.const = []; %allocate for constellation
audio_recorder.UserData.eyed  = []; %allocate for eye diagram


record(audio_recorder); %start recording
end


% CALLBACK FUNCTION
% This function will be called every [time_value] seconds, where time_value
% is specified above. Note that, as stated in the project MEMO, all the
% fields: pwr_spect, eyed, const and pack need to be assigned if you want
% to get outputs in the GUI.


function audioTimerFcn(recObj, event, handles)

%-----------------------------------------------------------
% THE CODE BELOW IS BASED ON COMPUTER EX 5 AND EX 6:
%-----------------------------------------------------------
disp('----------------------Callback triggered-------------------------')

%------------------------------------------------------------------------------
% Parameters
fc     = recObj.UserData.fc;
fs     = recObj.UserData.fs;                               % Sampling frequency [Hz]
Tsamp  = 1/fs;                                             % Sampling time [s]
Rb     = 500;                                              % Bit rate [bit/sec]
M      = 4;                                                % QPSK/4-QAM
bpsymb = log2(M);                                          % Number of bits per symbol
fsymb  = Rb/bpsymb;                                        % Symbol rate [symb/s]

fsfd   = fs/fsymb;                                         % Number of samples per symbol [samples/symb]
span   = 6;                                                % SRRC filter span in symbol durations

% Save the received signal
rx_signal = getaudiodata(recObj);
disp('Audio got')
rx_signal = rx_signal.';

% Plot the Received Signal
% figure;
% plot(1:length(rx_signal), abs(rx_signal));
% title('Received Signal')

disp(["Size of rx signal",size(rx_signal)])
% Signal detection
const = [(1 + 1i), (1 - 1i), (-1 - 1i), (-1 + 1i)]/sqrt(2);  % Constellation for QPSK/4-QAM

preamble_bits = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1];    % 13-digits Baker's Code
preamble_upsample = upsample(preamble_bits, fsfd);           % Upsample

rx_signal = rx_signal .* exp(-1i*2*pi*fc*...
    (0:length(rx_signal)-1)*Tsamp);                          % Downconversion

[pulse, ~] = rtrcpuls(0.2, 1/fsymb, fs, span);               % SRRC filter
pulse=pulse/sqrt(sum(pulse.^2));

% Check the preamble
preamble_signal = conv(pulse, preamble_upsample);            % Pulse shaping the upsampled preamble
disp('Preamble modulated')

% Correlate the received signal with the preamble
correlation = conv(rx_signal , flip(conj(preamble_signal))); % Cross-correlation
disp('Convolution completed')

% Plot the correlation diagram
% figure;
% plot(1:length(correlation), abs(correlation));
% grid on;
% title('Correlation')

% Plot the Cross-correlation Diagram
% figure;
% plot(correlation);
% title('Cross-correlation of Received Signal with Preamble');
% xlabel('Sample index');
% ylabel('Correlation');

[maxCorr, Tmax] = max(abs(correlation));                    % find the location of max correlation
disp(["MaxCorr: ",maxCorr])

% Calculate the ratio of maxcorr to the energy of the pulse
E_corr = sum(preamble_signal.^2);
ratio = maxCorr/(E_corr)^2;
disp(["Ratio: ",ratio])

% Judge whether the signal is captured
if ratio > 1e-3
    disp('Signal captured')
else
    disp('No signal')
    return;
end

Tx_hat = Tmax - length(preamble_signal);                  % find the time delay
disp(["Tmax: ",Tmax])

phi_hat=mod(angle(correlation(Tmax))*180/pi,360);         % find the phase delay

disp(['Delay is ', num2str(Tx_hat), ' samples'])
disp(' ')

rx_filtered = conv(rx_signal, pulse, 'same');             % Apply matched filtering
rx_rot=rx_filtered*exp(-1j*phi_hat/180*pi);               % Rotate based on the phase delay

% Extract the data portion after the preamble
rx_filtered = rx_rot(Tmax+1:end);                         % Crop the preamble part

% Crop the filtered signal to remove the convolution padding
rx_filtered = rx_filtered(span*fsfd+1:end-span*fsfd); 
r = rx_filtered(1:fsfd*216);

% Downsampling
rx_downsampled = rx_filtered(1:fsfd:fsfd*216);                 % Sample at symbol rate
rx_downsampled = rx_downsampled/max(abs(rx_downsampled));      % Normalization

x = rx_downsampled;

% Compute Euclidean distance to each constellation point and find the closest
dist = abs(repmat(rx_downsampled.', 1, length(const)) - repmat(const, length(rx_downsampled), 1));
% disp(["size of distance",size(dist)])
[~, idx] = min(dist, [], 2);                                   % Get the closest constellation points
% disp(["size of index",size(idx)])
% Convert symbol indices back to binary
m = de2bi(idx-1, bpsymb, 'left-msb');

% Reshape into a bitstream
received_bits = reshape(m.', [], 1);

% disp(["size of received bits",size(received_bits)])
pulse_train = rx_signal;
%------------------------------------------------------------------------------
%   HOW TO SAVE DATA FOR THE GUI
%   NOTE THAT THE EXAMPLE HERE IS ONLY USED TO SHOW HOW TO OUTPUT DATA
%------------------------------------------------------------------------------

% Step 1: save the estimated bits
recObj.UserData.pack = received_bits';

% Step 2: save the sampled symbols
recObj.UserData.const = x;

% Step 3: provide the matched filter output for the eye diagram (Note here no match filter is used. You should do that)
recObj.UserData.eyed.r = r((length(pulse)-1)/2:end-(length(pulse)-1)/2+1);
recObj.UserData.eyed.fsfd = fsfd;

% Step 4: Compute the PSD and save it. 
% !!!! NOTE !!!! the PSD should be computed on the BASE BAND signal BEFORE matched filtering
[pxx, f] = pwelch(pulse_train,1024,768,1024, fs); % note that pwr_spect.f will be normalized frequencies
f = fftshift(f); %shift to be centered around fs
f(1:length(f)/2) = f(1:length(f)/2) - fs; % center to be around zero
p = fftshift(10*log10(pxx/max(pxx))); % shift, normalize and convert PSD to dB
recObj.UserData.pwr_spect.f = f;
recObj.UserData.pwr_spect.p = p;

% In order to make the GUI look at the data, we need to set the
% receive_complete flag equal to 1:
recObj.UserData.receive_complete = 1; 

end
