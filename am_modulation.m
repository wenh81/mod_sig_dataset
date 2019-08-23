function [y, fs] = am_modulation(am_modulation_index, source_sample_length, snr_db, ...
    plot_modulated_signal, sound_demod, chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg)
% am modulation
%
% [input]
% - am_modulation_index: am modulation index. 0 = amsc(am suppressed carrier, 0.5 = amfc(am full carrier) 
% - source_sample_length:
% - snr_db: snr in db. if empty, noise is NOT added to signal
% - plot_modulated_signal: boolean
% - sound_demod: boolean
% - chan_type: standard fading channel(rician). one of 'gsmRAx6c1', 'gsmRAx4c2', 'cost207RAx6', 'cost207RAx4'
%   for details, use "help stdchan" in matlab command window
%   if empty, no fading channel
% - chan_fs: channel fs. used for sample period in constructing fading channel object.
%   ##### set to be same as audio source sample rate (wav file sample rate = 44.1e3)
%   even if chan_type is empty, "apply_carrier_offset" function use it.
% - fd: max doppler freq in hz. used in constructing fading channel object. 
%   recommend = 0. dont use fd > 0 (##### you may restart matlab program)
%   if chan_type is empty, dont care
% - save_iq: 0 = no save, 1 = save iq into 'am_modulation.mat' file.
% - max_freq_offset_hz: freq offset = randi([-max_freq_offset_hz, max_freq_offset_hz]). 
%   if 0, no freq offset
% - max_phase_offset_deg: phase offset = randi([-max_phase_offset_deg, max_phase_offset_deg]). 
%   if 0, no phase offset
%
% [usage]
% am_modulation(0, 8192, 10, 1, 0, 'gsmRAx6c1', 44.1e3, 0, 0, 100, 180);
% am_modulation(0, 8192, '', 1, 0, '', 44.1e3, 0, 0, 100, 180);
% am_modulation(0, 2^18, 10, 1, 1, '', 44.1e3, 0, 1, 100, 180);
% am_modulation(0, 2^18, '', 1, 1, 'gsmRAx4c2', 44.1e3, 0, 1, 100, 180);
%

plot_source_signal = 0;
sound_source = 0;
max_freq_of_source_signal = 5e3; % recommend = 5e3
[x, fs] = analog_source(source_sample_length, max_freq_of_source_signal, plot_source_signal, sound_source);

% am
% must satisfy fs > 2(fc + BW), where BW is the bandwidth of the modulating signal x.
ini_phase = 0;
% suppressed carrier am
carramp = am_modulation_index;
fc = max_freq_of_source_signal;
y = ammod(x, fc, fs, ini_phase, carramp);
size(y);

% ####### move to after baseband low pass filtering
% % add awgn noise to signal
% if ~isempty(snr_db)
%     y = awgn(y, snr_db, 'measured', 'db');
% end

if plot_modulated_signal
    plot_signal(y, fs, 'modulated');
end

% simulate rf receiver: change to baseband(freq down conversion)
t = (0 : length(y) - 1)' / fs;
y = y .* exp(-1i * 2 * pi * fc * t);

if plot_modulated_signal
    plot_signal(y, fs, 'baseband');
end

% ####### result: not good as fir1, filter coeff = 39 (fir1 filter coeff = 74) ##########
% % design filter with more contraints
% f_pass = pass_freq / fs;
% f_stop = f_pass + .15;
% stop_atten = 80;
% pass_ripple = 0.5;
% lpf = designfilt('lowpassfir', 'PassbandFrequency', f_pass, ...
%     'StopbandFrequency', f_stop, 'PassbandRipple', pass_ripple, ...
%     'StopbandAttenuation', stop_atten);
% length(lpf.Coefficients);
% y = filter(lpf, y);

% design low pass fir filter
filter_order = 74;
pass_freq = max_freq_of_source_signal;
filter_coeff = fir1(filter_order, pass_freq / fs * 2);

% low pass filtering
a = 1;
y = filter(filter_coeff, a, y);

% remove filter transient (180407)
y = y(round(filter_order / 2) : end);

% apply fading channel
if ~isempty(chan_type)
    y = apply_fading_channel(y, chan_type, chan_fs, fd);
end

% apply carrier offset
if max_freq_offset_hz || max_phase_offset_deg
    y = apply_carrier_offset(y, chan_fs, max_freq_offset_hz, max_phase_offset_deg);
end

% add awgn noise to signal
if ~isempty(snr_db)
    y = awgn(y, snr_db, 'measured', 'db');
end

% save iq into mat file
if save_iq
    mat_filename = sprintf('%s.mat', mfilename);
    save(mat_filename, 'y', 'fs', 'source_sample_length', 'snr_db', 'chan_type', 'chan_fs', 'fd');
end

if plot_modulated_signal
    plot_signal(y, fs, 'after baseband filter');
end

% you must hear mozart
if sound_demod
%     sound(real(y), fs);
    soundsc(real(y), fs);
end

end
