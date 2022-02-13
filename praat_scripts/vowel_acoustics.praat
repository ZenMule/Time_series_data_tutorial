#######################################################################
#######################################################################

# This program extracts duration, formants (F1-F4) and spectral moments
# from labeled intervals on a tier. The number of labeled tier and the
# amount of equidistant intervals can be specified using the form below.
# The output will be saved to two different log files. One contains
# durational and contextual information and the other formant related
# information.

# This program will extract formant values depending if the labeled
# interval contains a vowel sequence or monophthong. It the labeled
# interval is a vowel sequence, the script will use three sets of
# reference formant values to track formants in the three tertiles from
# the interval. Otherwise the script will only one set of reference
# formant values.

# The user can specify different reference values for vowel sequences
# monophthongs. # Remeber to change the reference formant values in
# the form for different vowels to make the formant tracking more accurate.

# Copyright (c) 2021-2022 Miao Zhang

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

#######################################################################
#######################################################################

form Extract Formant data from labelled intervals on a specific tier
   comment Basic settings:
   sentence Directory_name: /Users/zenmule/Programming/rProjects/Time_series_data_tutorial/recordings/vowels
   sentence Log_file_t _ait
   sentence Log_file_d _aid
   sentence Interval_label ai
   positive Labeled_tier_number 2
   integer Syllable_tier_number 1
   positive Number_of_chunks 10
   boolean Measure_vowel_sequence 1

   comment Formant extracting settings:
   positive Analysis_points_time_step 0.005
   #positive Record_with_precision 1
   positive Formant_ceiling 4000
   positive Number_of_formants 4
   positive Window_length 0.025
   positive Preemphasis_from 50
   positive Buffer_window_length 0.04
endform

if measure_vowel_sequence
  beginPause: "Reference formant values for vowel sequences"
    comment: "1st tertile of the labeled interval:"
    positive: "F1_ref_init", 760
    positive: "F2_ref_init", 1400
    positive: "F3_ref_init", 2300
    comment: "2nd tertile of the labeled interval:"
    positive: "F1_ref_med", 650
    positive: "F2_ref_med", 1800
    positive: "F3_ref_med", 2300
    comment: "3rd tertile of the labeled interval:"
    positive: "F1_ref_fin", 420
    positive: "F2_ref_fin", 2300
    positive: "F3_ref_fin", 2650
    comment: "Reference F4 and F5:"
    positive: "F4_ref", 3600
    positive: "F5_ref", 4660
  endPause: "Continue", 1

else
  beginPause: "Reference formant values for monophthongs:"
    positive: "F1_ref", 500
    positive: "F2_ref", 1500
    positive: "F3_ref", 2500
    positive: "F4_ref", 3600
    positive: "F5_ref", 4660
  endPause: "Continue", 1

endif

clearinfo

#######################################################################
#######################################################################

# Create headers for the two output log files
fileappend 'directory_name$''log_file_t$'.txt File_name'tab$'Seg_num'tab$'Seg'tab$'Syll'tab$'t'tab$'t_m'tab$'F1'tab$'F2'tab$'F3'tab$'F4'tab$'COG'tab$'sdev'tab$'skew'tab$'kurt'tab$''newline$'
fileappend 'directory_name$''log_file_d$'.txt File_name'tab$'Seg_num'tab$'Seg'tab$'Dur'tab$'Seg_prev'tab$'Seg_subs'tab$'Syll'tab$'Syll_dur'newline$'

#######################################################################

# Create a list of all files in the target directory
Create Strings as file list: "fileList", directory_name$ + "/*.wav"
selectObject: "Strings fileList"
num_file = Get number of strings

# Open the soundfile in Praat
for i_file from 1 to num_file
	selectObject: "Strings fileList"
	fileName$ = Get string: i_file
	Read from file: directory_name$ + "/" + fileName$

  # Save the sound file name
  sound_name$ = selected$("Sound")

  # Save the sound file
  sound_file = selected("Sound")
  printline Start working on sound file < 'sound_name$'.wav >.

	# Open the corresponding TextGrid file in Praat
	Read from file: directory_name$ + "/" + sound_name$ + ".TextGrid"
	textGrid_file = selected("TextGrid")

	# Work through all labeled intervals on the target tier
	num_labels = Get number of intervals: labeled_tier_number


  # Work on individual labeled segments
  for i_label from 1 to num_labels
    select 'textGrid_file'
	  label$ = Get label of interval: labeled_tier_number, i_label

    # If the label is the specified interval label
    if label$ = interval_label$
      printline Start working on labeled interval 'i_label': < 'label$' >.

      # Get the duration of the labeled interval
		  label_start = Get starting point: labeled_tier_number, i_label
		  label_end = Get end point: labeled_tier_number, i_label
      dur = label_end - label_start

      # Get the label of the current segment
      seg$ = Get label of interval: labeled_tier_number, i_label

      # Get the label of the previous segment if it is labeled
      seg_prev$ = Get label of interval: labeled_tier_number, (i_label-1)
      if seg_prev$ = ""
        seg_prev$ = "NA"
      endif

      # Get the label of the subsequent segment if it is labeled
			seg_subs$ = Get label of interval: labeled_tier_number, (i_label+1)
      if seg_subs$ = ""
        seg_subs$ = "NA"
      endif

      # Get the lable of the syllable from the syllable tier if there is one
      if syllable_tier_number <> 0
        # Get the index of the current syllable that the labeled segment occurred in
        syll_num = Get interval at time: syllable_tier_number, (label_start + (label_end - label_start)/2)

        # Get the duration of the syllable
        syll_start = Get starting point: syllable_tier_number, syll_num
        syll_end = Get end point: syllable_tier_number, syll_num
        syll_dur = syll_end - syll_start
  			syll$ = Get label of interval: syllable_tier_number, syll_num
      else
        # If there is no syllable tier, the label of syllable is NA, and the duration is 0
        syll_dur = 0
        syll$ = "NA"
      endif

      # Write the information obtained above to log file d
      fileappend 'directory_name$''log_file_d$'.txt 'fileName$''tab$''i_label''tab$''seg$''tab$''dur:3''tab$''seg_prev$''tab$''seg_subs$''tab$''syll$''tab$''syll_dur:3''newline$'

      #######################################################################

      ## Formant analysis and spectral analysis
      # Extract the formant object first
			fstart = label_start - buffer_window_length
			fend = label_end + buffer_window_length
			select 'sound_file'
			Extract part: fstart, fend, "rectangular", 1, "no"
			extracted = selected("Sound")

      # Get the duration of each equidistant interval of a labeled segment
			chunk_length  = dur/number_of_chunks

      select 'extracted'
      To Formant (burg): analysis_points_time_step, number_of_formants, formant_ceiling, window_length, preemphasis_from
			formant_burg = selected("Formant")
			num_form = Get minimum number of formants

      # Set how many formants the algorithm should track
      if num_form = 2
        number_tracks = 2
      elif num_form = 3
        number_tracks = 3
      else
				number_tracks = 4
			endif

      # Extract formant values
      if measure_vowel_sequence
        # If the labeled interval is a vowel sequence
        for i_chunk from 1 to number_of_chunks
          if i_chunk <= number_of_chunks/3
            # Track the formants
            select 'formant_burg'
            Track: number_tracks, 'f1_ref_init', 'f2_ref_init', 'f3_ref_init', 'f4_ref', 'f5_ref', 1, 1, 1
      			formant_tracked = selected("Formant")

            # Get the start, end, and middle point of the interval
            chunk_start = buffer_window_length + (i_chunk - 1) * chunk_length
            chunk_end = buffer_window_length + i_chunk * chunk_length
            chunk_mid = buffer_window_length + chunk_length/2 + (i_chunk - 1) * chunk_length

            # Write to the log file t
            fileappend 'directory_name$''log_file_t$'.txt 'fileName$''tab$''i_label''tab$''seg$''tab$''syll$''tab$''i_chunk''tab$''chunk_mid:3''tab$'

            select 'formant_tracked'
            # F1
            f1 = Get mean: 1, chunk_start, chunk_end, "hertz"
            if f1 = undefined
              f1 = 0
            endif

            # F2
            f2 = Get mean: 2, chunk_start, chunk_end, "hertz"
    				if f2 = undefined
    					f2 = 0
    				endif

            # F3
            f3 = Get mean: 3, chunk_start, chunk_end, "hertz"
    				if f3 = undefined
    					f3 = 0
    				endif

            # F4
            f4 = Get mean: 4, chunk_start, chunk_end, "hertz"
    				if f4 = undefined
    					f4 = 0
    				endif

            # Write the formant values to the log file t
    				fileappend 'directory_name$''log_file_t$'.txt 'f1:0''tab$''f2:0''tab$''f3:0''tab$''f4:0''tab$'

          elif i_chunk <= 2*number_of_chunks/3
            # Track the formants
            select 'formant_burg'
            Track: number_tracks, 'f1_ref_med', 'f2_ref_med', 'f3_ref_med', 'f4_ref', 'f5_ref', 1, 1, 1
      			formant_tracked = selected("Formant")

            # Get the start, end, and middle point of the interval
            chunk_start = buffer_window_length + (i_chunk - 1) * chunk_length
            chunk_end = buffer_window_length + i_chunk * chunk_length
            chunk_mid = buffer_window_length + chunk_length/2 + (i_chunk - 1) * chunk_length

            # Write to the log file t
            fileappend 'directory_name$''log_file_t$'.txt 'fileName$''tab$''i_label''tab$''seg$''tab$''syll$''tab$''i_chunk''tab$''chunk_mid:3''tab$'

            select 'formant_tracked'
            # F1
            f1 = Get mean: 1, chunk_start, chunk_end, "hertz"
            if f1 = undefined
              f1 = 0
            endif

            # F2
            f2 = Get mean: 2, chunk_start, chunk_end, "hertz"
    				if f2 = undefined
    					f2 = 0
    				endif

            # F3
            f3 = Get mean: 3, chunk_start, chunk_end, "hertz"
    				if f3 = undefined
    					f3 = 0
    				endif

            # F4
            f4 = Get mean: 4, chunk_start, chunk_end, "hertz"
    				if f4 = undefined
    					f4 = 0
    				endif

            # Write the formant values to the log file t
    				fileappend 'directory_name$''log_file_t$'.txt 'f1:0''tab$''f2:0''tab$''f3:0''tab$''f4:0''tab$'

          else
            # Track the formants
            select 'formant_burg'
            Track: number_tracks, 'f1_ref_fin', 'f2_ref_fin', 'f3_ref_fin', 'f4_ref', 'f5_ref', 1, 1, 1
      			formant_tracked = selected("Formant")

            # Get the start, end, and middle point of the interval
            chunk_start = buffer_window_length + (i_chunk - 1) * chunk_length
            chunk_end = buffer_window_length + i_chunk * chunk_length
            chunk_mid = buffer_window_length + chunk_length/2 + (i_chunk - 1) * chunk_length

            # Write to the log file t
            fileappend 'directory_name$''log_file_t$'.txt 'fileName$''tab$''i_label''tab$''seg$''tab$''syll$''tab$''i_chunk''tab$''chunk_mid:3''tab$'

            select 'formant_tracked'
            # F1
            f1 = Get mean: 1, chunk_start, chunk_end, "hertz"
            if f1 = undefined
              f1 = 0
            endif

            # F2
            f2 = Get mean: 2, chunk_start, chunk_end, "hertz"
    				if f2 = undefined
    					f2 = 0
    				endif

            # F3
            f3 = Get mean: 3, chunk_start, chunk_end, "hertz"
    				if f3 = undefined
    					f3 = 0
    				endif

            # F4
            f4 = Get mean: 4, chunk_start, chunk_end, "hertz"
    				if f4 = undefined
    					f4 = 0
    				endif

            # Write the formant values to the log file t
    				fileappend 'directory_name$''log_file_t$'.txt 'f1:0''tab$''f2:0''tab$''f3:0''tab$''f4:0''tab$'
          endif

          # Remove tracked formant object
          select 'formant_tracked'
          Remove

          #######################################################################

  			  #Getting spectral moments
  				select 'sound_file'
  				Extract part: (i_chunk - 1) * chunk_length, i_chunk * chunk_length, "rectangular", 1, "no"
  				chunk_part = selected("Sound")
  				spect_part = To Spectrum: "yes"
  				grav = Get centre of gravity: 2
  				sdev = Get standard deviation: 2
  				skew = Get skewness: 2
  				kurt = Get kurtosis: 2

          # Write to the log file
  				fileappend 'directory_name$''log_file_t$'.txt 'grav:0''tab$''sdev:0''tab$''skew:0''tab$''kurt:0''newline$'

  				select 'chunk_part'
  				Remove
  				select 'spect_part'
  				Remove
  			endfor

      else
        # If the lebeled interval is a monophthong
        for i_chunk from 1 to number_of_chunks
          # Track the formants
          select 'formant_burg'
          Track: number_tracks, 'f1_ref', 'f2_ref', 'f3_ref', 'f4_ref', 'f5_ref', 1, 1, 1
          formant_tracked = selected("Formant")

          # Get the start, end, and middle point of the interval
          chunk_start = buffer_window_length + (i_chunk - 1) * chunk_length
          chunk_end = buffer_window_length + i_chunk * chunk_length
          chunk_mid = buffer_window_length + chunk_length/2 + (i_chunk - 1) * chunk_length

          # Write to the log file t
          fileappend 'directory_name$''log_file_t$'.txt 'fileName$''tab$''i_label''tab$''seg$''tab$''syll$''tab$''i_chunk''tab$''chunk_mid:3''tab$'

          select 'formant_tracked'
          # F1
          f1 = Get mean: 1, chunk_start, chunk_end, "hertz"
          if f1 = undefined
            f1 = 0
          endif

          # F2
          f2 = Get mean: 2, chunk_start, chunk_end, "hertz"
          if f2 = undefined
            f2 = 0
          endif

          # F3
          f3 = Get mean: 3, chunk_start, chunk_end, "hertz"
          if f3 = undefined
            f3 = 0
          endif

          # F4
          f4 = Get mean: 4, chunk_start, chunk_end, "hertz"
          if f4 = undefined
            f4 = 0
          endif

          # Write the formant values to the log file t
          fileappend 'directory_name$''log_file_t$'.txt 'f1:0''tab$''f2:0''tab$''f3:0''tab$''f4:0''tab$'

        # Remove tracked formant object
        select 'formant_tracked'
        Remove

        #######################################################################

        #Getting spectral moments
        select 'sound_file'
        Extract part: (i_chunk - 1) * chunk_length, i_chunk * chunk_length, "rectangular", 1, "no"
        chunk_part = selected("Sound")
        spect_part = To Spectrum: "yes"
        grav = Get centre of gravity: 2
        sdev = Get standard deviation: 2
        skew = Get skewness: 2
        kurt = Get kurtosis: 2

        # Write to the log file
        fileappend 'directory_name$''log_file_t$'.txt 'grav:0''tab$''sdev:0''tab$''skew:0''tab$''kurt:0''newline$'

        select 'chunk_part'
        Remove
        select 'spect_part'
        Remove
        endfor

      endif

      # Remove formant objects
      select 'formant_burg'
      Remove

		else
			#do nothing
   	endif
	endfor

select 'extracted'
Remove
select 'textGrid_file'
Remove
select 'sound_file'
Remove

endfor

select all
Remove

printline "All done!"
