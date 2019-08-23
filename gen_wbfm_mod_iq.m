function [iq] = gen_wbfm_mod_iq(instance_length, iq_sample_length, snr_db, ...
    chan_type, chan_fs, max_freq_offset_hz, max_phase_offset_deg, iq_from_1st_sample)
% ############################################################################
% simulate fm radio broadcasting signal (88 ~ 108 mhz)
% "fm_radio_modulation.m" is replaced with "fm_broadcasting_modulation_comm_system_object.m",
% in which 'comm.FMBroadcastModulator', 'comm.FMBroadcastDemodulator',
% freq_dev = 75e3, and max_freq_of_source_signal = 15e3 is used.
% only good from r2017b
% previous version: "gen_wbfm_mod_iq(180720).m"
% ############################################################################

plot_modulated_signal = 0;
sound_demod = 0;
fd = 0; % doppler freq
save_iq = 0;
% max_phase_offset_deg = 180;

% fm radio
% freq_dev = 75e3;

modulated_sample_length = iq_sample_length;
% source_sample_length = iq_sample_length * 2;
% max_start_idx = round(iq_sample_length * .5);

iq = zeros(instance_length, iq_sample_length);
for n = 1 : instance_length
    [pre_iq, ~] = ...
        fm_broadcasting_comm_system_object(modulated_sample_length, snr_db, ...
        plot_modulated_signal, sound_demod, ...
        chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    % ######## pre_iq length is exactly same as modulated_sample_length(= iq_sample_length)
    
%     [pre_iq, ~] = ...
%         wbfm_modulation(source_sample_length, freq_dev, snr_db, plot_modulated_signal, sound_demod, ...
%         chan_type, chan_fs, fd, save_iq, max_freq_offset_hz, max_phase_offset_deg);
    
%     if iq_from_1st_sample
%         start_idx = 1;
%     else
%         start_idx = randi([2, max_start_idx]);
%     end
    
%     start_idx = 1;
%     pre_iq = pre_iq(start_idx : start_idx + iq_sample_length - 1);
    
    % ##############################################################
    % #### normalize is needed?
    % #### it give "nan" when all pre_iq is zero
    % ##############################################################
    % normalize
    pre_iq = pre_iq / max(abs(pre_iq));
    
    % vertical stack into iq
    iq(n, :) = pre_iq;
end

end

