set test_index=1
:start
copy 4K_FF.txt sdcard_data\%test_index%.txt
set /a test_index=test_index+1
goto start
