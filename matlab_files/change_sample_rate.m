function new_signal = change_sample_rate(old_signal, old_fs, new_fs) 
  % Change the sample rate of a singal from old_fs to new_fs

  [P,Q] = rat(new_fs/old_fs); 
  new_signal = resample(old_signal, P, Q);

end
