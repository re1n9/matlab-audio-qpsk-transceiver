% pack = message to be transmitted (consists of 432 bits from the GUI, always!)
% fc = carrier frequency
function transmitter(pack,fc)

fs         = 15000;                                                 % sampling frequency [Hz]
Tsamp      = 1/fs;                                                  % Sampling time [s]
Rb         = 500;                                                   % bit rate [bit/sec]
M          = 4;                                                     % QPSK
bpsymb     = log2(M);                                               % Number of bits per symbol
fsymb      = Rb/bpsymb;                                             % Symbol rate [symb/s]
fsfd       = fs/fsymb;                                              % Number of samples per symbol [samples/symb]

span       = 6;                                                     % SRRC filter span in symbol durations
[pulse, ~] = rtrcpuls(0.2,1/fsymb,fs,span);                         % SRRC filter for pulse shaping
pulse      = pulse/sqrt(sum(pulse.^2));                             % Normalize to energy = 1 

const      = [(1 + 1i), (1 - 1i), (-1 - 1i), (-1 + 1i)]/sqrt(2);    % Constellation for QPSK/4-QAM

% Define preamble
preamble   = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1];              % 13-digits Baker's code

m          = buffer(pack.', bpsymb)';                               % Group bits into pairs
m_idx      = bi2de(m, 'left-msb')'+1; 

x          = const(m_idx);                                          % QPSK Modulator Mapper

x_withPA   = [preamble, zeros(1,12), x, zeros(1,30)];               % Add preamble to the actual data signal
x_upsample = upsample(x_withPA, fsfd);                              % Space the symbols fsfd apart, to enable pulse shaping using conv.

s          = conv(pulse, x_upsample);                               % Pulse shaping

tx_signal  = s;                                                     % Signal to transmitt
tx_signal  = tx_signal.*exp(1i*2*pi*fc*...
            (0:length(tx_signal)-1)*Tsamp);                         % Upconversion 

tx_signal  = real(tx_signal);                                       % Only real part
tx_signal  = tx_signal/max(abs(tx_signal));                         % Prevent clipping of waveforms

player     = audioplayer(tx_signal, fs);                            % create an audioplayer object to play the noise at a given sampling frequency

playblocking(player);                                               % Play the transmitted signal
audiowrite("tx_signal.wav", tx_signal,fs)                         % Store it as the .wav file for testing


