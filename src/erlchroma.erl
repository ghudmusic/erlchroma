-module(erlchroma).

-export([]).




create_fingerprint(Mp3)->

		ok.
	    
	    
create_fingerprint_folder(Folder_path)->
		{ok,Directlist} =file:list_dir(Folder_path),
		lists:map(
		fun(File)-> Payload = create_fingerprint(File) end,Directlist).

%%ffmpeg -f f64be -ar 44100 -i out/first_wave.raw out/first_wave.mp3
