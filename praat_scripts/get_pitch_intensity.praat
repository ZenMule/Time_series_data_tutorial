# This script extract the total duration and F0 from equidistant intervals on a labeled tier.
# The number of labeled tier and the amount of equidistant intervals can be specified using the form below.
# The output will be saved to two different log files. 
# One has the duration information and the other one F0 information.
# This script does not extract F0 values from labeled tier where the token is shorter than 50ms.

# Copyright@ Miao Zhang, University at Buffalo, 2021. 
# Feel free to use but please cite when you use it.


#######################################################################
#######################################################################


form Extract Pitch data from labelled intervals
   sentence Directory_name: /Users/zenmule/Programming/rProjects/Time_series_data_tutorial/recordings/tones
   sentence Log_file_t _f0t
   sentence Log_file_dyn _f0d
   positive Numintervals 10
   positive Labeled_tier_number 3
   positive Analysis_points_time_step 0.005
   positive Record_with_precision 1
   comment F0 Settings:
   positive F0_minimum 70
   positive F0_maximum 500
   positive Octave_jump 0.10
   positive Voicing_threshold 0.65
   positive Pitch_window_threshold 0.05
endform


#######################################################################
#######################################################################


# Create header rows for both log files
fileappend 'directory_name$''log_file_t$'.txt File_name'tab$'Segment'tab$'t'tab$'t_m'tab$'F0'tab$'Int'newline$'
fileappend 'directory_name$''log_file_dyn$'.txt File_name'tab$'Segment'tab$'Dur'tab$'F0_min'tab$'F0_min_loc'tab$'F0_max'tab$'F0_max_loc'tab$'F0_mgnt'tab$'F0_changerate'newline$'

# Create a list of all files in the target directory
Create Strings as file list: "fileList", directory_name$ + "/*.wav"
selectObject: "Strings fileList"
num_file = Get number of strings

# Open the soundfile in Praat
for ifile from 1 to num_file
	selectObject: "Strings fileList"
	fileName$ = Get string: ifile
	Read from file: directory_name$ + "/" + fileName$

	sound_file = selected("Sound")
	sound_name$ = selected$("Sound")

	# Open the corresponding TextGrid file in Praat
	Read from file: directory_name$ + "/" + sound_name$ + ".TextGrid"
	textGridID = selected("TextGrid")

	# Work through all labeled intervals on the target tier
	num_labels = Get number of intervals: labeled_tier_number


#######################################################################

	
	for i_label from 1 to num_labels
		select 'textGridID'
		
		# Get the name of the label
		label$ = Get label of interval: labeled_tier_number, i_label

		if label$ <> ""
			# When the label name is not empty
			fileappend  'directory_name$''log_file_dyn$'.txt 'sound_name$''tab$'

			# Get the starting and end time point of the label, 
			# and calculate the total duration
			label_start = Get start time of interval: labeled_tier_number, i_label
			label_end = Get end time of interval: labeled_tier_number, i_label
			dur = label_end - label_start

			# Save the duration information to its log file
			fileappend 'directory_name$''log_file_dyn$'.txt 'label$''tab$''dur:3''tab$'


#######################################################################	
		

			# Work on individual labeled intervals. Extract pitch and intensity object
			select 'sound_file'

			# Get the boundaries of the target F0-obtaining interval
			pstart = label_start - pitch_window_threshold
			pend = label_end + pitch_window_threshold

			# Extract the sound part from the label
			Extract part: pstart, pend, "rectangular", 1, "yes"
			intv_ID = selected("Sound")

			# If the label is shorter than 50ms, output NA in 't', 't_m', and 'F0' columns
			if dur < 0.05
				select 'intv_ID'
				fileappend NA'tab$'NA'tab$'NA'newline$'
				Remove
			else
				# Extract the pitch object first
				select 'intv_ID'
				To Pitch (ac): 0, f0_minimum, 15, "yes", 0.03, voicing_threshold, octave_jump, 0.35, 0.14, f0_maximum
				pitch_ID = selected("Pitch")

				# Extract the intensity object 
				select 'intv_ID'
				Filter (pass Hann band): 40, 4000, 100
				intv_ID_filt = selected("Sound")
				To Intensity: f0_minimum, 0, "yes"
				intense_ID = selected("Intensity")


#######################################################################


				# Overall pitch dynamic analysis
				# F0 minimum
				select 'pitch_ID'
				f0_min = Get minimum: label_start, label_end, "Hertz", "parabolic"
				f0_min_time = Get time of minimum: label_start, label_end, "Hertz", "parabolic"
				f0_min_loc = (f0_min_time - label_start)/dur

				if f0_min = undefined
					fileappend 'directory_name$''log_file_dyn$'.txt NA'tab$'NA'tab$'
				else
					fileappend 'directory_name$''log_file_dyn$'.txt 'f0_min:2''tab$''f0_min_loc:2''tab$'
				endif
				
				# F0 maximum
				f0_max = Get maximum: label_start, label_end, "Hertz", "parabolic"
				f0_max_time = Get time of maximum: label_start, label_end, "Hertz", "parabolic"
				f0_max_loc = (f0_max_time - label_start)/dur

				if f0_max = undefined
					fileappend 'directory_name$''log_file_dyn$'.txt NA'tab$'NA'tab$'
				else
					fileappend 'directory_name$''log_file_dyn$'.txt 'f0_max:2''tab$''f0_max_loc:2''tab$'
				endif

				# F0 dynamics

				if f0_max <> undefined and f0_min <> undefined 
					if f0_max_time > f0_min_time
						f0_mgnt = f0_max - f0_min
						f0_transtime = f0_max_time - f0_min_time
						f0_changerate = f0_mgnt/f0_transtime
					else
						f0_mgnt = f0_min - f0_max
						f0_transtime = f0_min_time - f0_max_time
						f0_changerate = f0_mgnt/f0_transtime
					endif
					fileappend 'directory_name$''log_file_dyn$'.txt 'f0_mgnt:2''tab$''f0_changerate:2''newline$'
				else
					fileappend 'directory_name$''log_file_dyn$'.txt NA'tab$'NA'newline$'
				endif

				
#######################################################################	


				# Pitch and intensity by-time interval analysis
				
				for i_intv from 1 to numintervals
					size = dur/numintervals

					# Get the start, end, and middle point of the interval
					intv_start = label_start + (i_intv-1) * size
					intv_end = label_start + i_intv * size
					intv_mid = intv_start + (intv_end - intv_start)/2 - label_start
					
					# Get the mean F0 of the time interval
					select 'pitch_ID'
					f0_intv = Get mean: intv_start, intv_end, "Hertz"
					
					# Get the mean intensity of the time interval
					select 'intense_ID'
					intense_intv = Get mean: intv_start, intv_end, "dB"

					if f0_intv = undefined
						if intense_intv = undefined
							fileappend  'directory_name$''log_file_t$'.txt 'sound_name$''tab$''label$''tab$'NA'tab$'NA'tab$'NA'tab$'NA'newline$'
						else
							fileappend  'directory_name$''log_file_t$'.txt 'sound_name$''tab$''label$''tab$''i_intv''tab$''intv_mid:3''tab$'NA'tab$''intense_intv:2''newline$'
						endif
					else
						if intense_intv = undefined
							fileappend  'directory_name$''log_file_t$'.txt 'sound_name$''tab$''label$''tab$''i_intv''tab$''intv_mid:3''tab$''f0_intv:2''tab$'NA'newline$'
						else
							fileappend  'directory_name$''log_file_t$'.txt 'sound_name$''tab$''label$''tab$''i_intv''tab$''intv_mid:3''tab$''f0_intv:2''tab$''intense_intv:2''newline$'
						endif
					endif
				endfor
				
				select 'pitch_ID'
				plus 'intv_ID'
				plus 'intense_ID'
				Remove
					
			endif
		endif
	endfor
	
	select 'sound_file'
	Remove

endfor

select all
Remove
