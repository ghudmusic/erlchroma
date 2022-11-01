-module(erlchroma_port).

-export([]).

-export([start/0,get_state/0,start_multiple/1,start/1, stop/0, init/1,decode_batch/0,create_fingerprints/0,
         load_fingerprints_ets/0,get_duration_audio_wav/1,get_audio_parts_wav/1]).


%% @doc 
%% 1  write code to decode media file into a pcm format--done
%% 	  code to then create fingreprint--done
%%	  code to store fingerprints in binary file/code to also load fingerprints into ets file--done
%% 	  code to then store in ets along with pseudo id of artist--done
%% 2. code to then be finding songs as i stream the data from a url and calculate length of song which is being played/streamed--in process
%%	  calculation is done by finding songs which are being played and then using the timestamp to increase  duration of track 





%% @doc




%% @doc for testing for running multiple instances of a command 
%%Command = "/usr/bin/fpcalc -ts -chunk 1  -length 2222 -overlap -json http://172.23.0.2:8005",
%%["/usr/bin/fpcalc -ts -chunk 2 -overlap -json http://cassini.shoutca.st:8922/;?type=http&nocache=115",
%%"/usr/bin/fpcalc -ts -chunk 2 -overlap -json http://yfm1079accra.atunwadigital.streamguys1.com/yfm1079accra"
%%%%Command = "/usr/bin/fpcalc -ts -chunk 1 -length 2222 -overlap -json http://yfm1079accra.atunwadigital.streamguys1.com/yfm1079accra",
%%] Command = "ffmpeg -re -i kiz.wav -c copy -listen 1 -f wav http://172.23.0.2:8005"
-spec start_multiple(list())->list().
start_multiple(Radio_stations)->
	List_pids = lists:map(fun(Radiostat) -> start(Radiostat) end,lists:seq(1,length(Radio_stations))).


%% @doc for starting the port command
-spec start()->error_no_prog_specified | pid().
start() ->
    error_no_prog_specified.


start(ExtPrg) ->
    spawn(?MODULE, init, [ExtPrg]).


%% @doc for stopping the port program
-spec stop()-> stop.
stop() ->
    ?MODULE ! stop.



-spec get_state()-> {ok,list()}.
get_state() ->
	Response = {get_state_data,self()} ! ?MODULE,
	{ok,Response}.


-spec decode_batch()-> list().
decode_batch()->
    %%ffmpeg -i out/open_gate.mp3 -acodec pcm_s16le out/open_gate_new.wav
	{ok,Temp_folder} = application:get_env(erlchroma,temp_folder),
	{ok,Decoded_folder} = application:get_env(erlchroma,decoded_folder),
	{ok,Directlist} =file:list_dir(Temp_folder),
	lists:map(
		fun(File_name)-> 
			Path_track = lists:concat([Temp_folder,"/",File_name]),
			Decode_name = lists:concat([Decoded_folder,"/",lists:nth(1,string:tokens(File_name,"."))]),
			Command_Exec = ["/usr/bin/ffmpeg","-i",Path_track,"-f","wav",Decode_name],
			io:format("~ncommand to be executed is ~p",[Command_Exec]),
			case exec:run(Command_Exec, [sync,{stdout,print}]) of 
				{ok,Res} ->
				   io:format("~n status after executation is ~p",[Res]);
				{error,Res}->
				   io:format("~n error converting file ~p",[Res])	
			end	
		end,
	Directlist).



-spec create_fingerprints()-> list().
create_fingerprints()->
	{ok,Track_converted_folder} = application:get_env(erlchroma,decoded_folder),
	{ok,Finpgerprint_folder} = application:get_env(erlchroma,finpgerprint_folder),
	{ok,Directlist} =file:list_dir(Track_converted_folder),
	lists:map(
		fun(File_name)-> 
			Path_convert_track = lists:concat([Track_converted_folder,"/",File_name]),
            Duration_track = proplists:get_value(total_seconds,get_duration_audio_wav(Path_convert_track)),
			Command_Exec = ["/usr/bin/fpcalc","-chunk","1","-json","-overlap","-length",erlang:integer_to_list(Duration_track),Path_convert_track],
			Fingerprint_name = erlang:binary_to_list(uuid:uuid_to_string(uuid:get_v4(), binary_standard)),
			Proplist_binary = [{name_file,File_name},{id_file,Fingerprint_name},{duration,Duration_track}],
			io:format("~ncommand to be executed is ~p",[Command_Exec]),
			case exec:run(Command_Exec, [sync,stdout]) of 
				{ok,[{stdout,List_fingerprint}]} ->
				   ok = file:write_file(lists:concat([Finpgerprint_folder,"/",File_name]), io_lib:format("~p.", [[{fingerprint,List_fingerprint}|Proplist_binary]]));
				{error,Res}->
				   io:format("~n error converting file ~p",[Res])	
			end	
		end,
    Directlist).	


%% @doc this is for loading fingerprints int the ets 
-spec load_fingerprints_ets()->list()|atom().
load_fingerprints_ets()->
	case ets:info(fingerprint) of 
		undefined ->
			ets:new(fingerprints, [duplicate_bag, named_table]);
		_ ->
			ok
	end,
	{ok,Fingerprint_folder} = application:get_env(erlchroma,finpgerprint_folder),
	{ok,Directlist} = file:list_dir(Fingerprint_folder),
	%%io:format("~njson data is ~p",[Directlist]),
	lists:map(
		fun(File_name)->
			%%io:format("~nfile name is  ~p",[File_name]),
			{ok,[Data]} = file:consult(lists:concat([Fingerprint_folder,"/",File_name])),
			Id_track =  proplists:get_value(id_file,Data),
			Name_file = proplists:get_value(name_file,Data),
			Fingerprint_data = proplists:get_value(fingerprint,Data),
			%%io:format("~nfdata is ~n~p~p~p",[Data,Id_track,Fingerprint_data]),
			lists:map(
				fun(Fdata)->
					%%io:format("~nmap data is ~p",[Fdata]),
					Json_data = jsx:decode(unicode:characters_to_binary(Fdata)),
					%%io:format("~njson data is ~p",[Json_data]),
					Fprint = proplists:get_value(<<"fingerprint">>,Json_data),
					ets:insert(fingerprints,{Fprint,Id_track,Name_file})
				end,
			Fingerprint_data)
			%%io:format("~nfingperprint data is ~p",[Data])
		end,
	Directlist),
	ok.



	




%%for initilizing the port for runnig commands
%%will use a dictinary to store the current song/songs which has been identfied,current timestamp
%%have to find out what is an acceptable time difference to know a song has finished playing
%% Data = #{current_songs => [{id(),starttime(),clength()}]}. 
-spec init([string() | char()]) -> pid().
init(ExtPrg) ->
    process_flag(trap_exit, true),
    {ok,Pid,Ospid} = exec:run(ExtPrg, [stdout, stderr,monitor]),
    loop(Pid,Ospid,ExtPrg,[]).


%%for looping and executing main function
-spec loop(pid(),integer(),[string() | char()],list()) -> pid().
loop(Pid,Ospid,ExtPrg,State_data) ->
    receive
		{'DOWN',Ospid,process,Pid,normal}->
			io:format("~n os process ~p with process ~p is down ~n",[Ospid,Pid]),
			start(ExtPrg);
		{'EXIT', Port, Reason} ->
			io:format("~n Port was killed for reason ~p ~p ~nrestarting port~n",[Port,Reason]),
			exit(processexited);
		{stdout,Ospid,Fingerprint_data_station} ->
			Process_data = process_data(State_data,Fingerprint_data_station),
			loop(Pid,Ospid,ExtPrg,Process_data);
		{get_state_data,Pid} ->
			Pid ! State_data,
			loop(Pid,Ospid,ExtPrg,State_data)
    end.


%%first of all get the list of ids for a which are being processed in a song
%%after the song finishes playing remove the id from the list of songs
%%condition for finished song is that there musnt be less than 10 seconds from the time the song was last played
%%remove it from the list of ids of songs being identified and store it in a new table for played songs
%%start the loop again by receiving new data
-spec process_data(list(),binary())->list().
process_data(State_data,Data_station)->
	Json_data = jsx:decode(unicode:characters_to_binary(Data_station)),
	Timestamp_data = proplists:get_value(<<"timestamp">>,Json_data),
	Fingerprint_index = proplists:get_value(<<"fingerprint">>,Json_data),
	io:format("~nstate data is ~p,~nresultdata is ~p",[State_data,Fingerprint_index]),
	%%io:format("~nstate data is ~p~n json data is ~p ~p",[State_data,Timestamp_data,Fingerprint_index]),
	case ets:lookup(fingerprints,Fingerprint_index) of 
		[]->
			State_data;
		Ets_results ->
			{Process_accum_end,_} = 
			lists:foldl(
				fun({Fprint_song,Id_song_ets,Artist_name_ets},{Accum_State,New_timestamp})->
						{Process_tracks,Check_fresh_song_status} =
							lists:mapfoldl(
								fun(Single_song_state_data = {Id_song_playing,Startime_playing,Length_song_playing,Status},Check_fresh_song)->
									%%io:format("~n new timestamp ~p~n and  old timestamp ~p",[New_timestamp,Startime_playing]),
									Difference_last_play = New_timestamp - (Startime_playing+Length_song_playing),
									case  {Id_song_ets =:= Id_song_playing,Difference_last_play =< 2} of 
										{true,true} ->
											New_length_playing = New_timestamp - Startime_playing,
											{{Id_song_playing,Startime_playing,New_length_playing,processing},Check_fresh_song+1};
										{true,false} ->
											{{Id_song_playing,Startime_playing,Length_song_playing,finished},Check_fresh_song};
										{false,_} ->
											{{Id_song_playing,Startime_playing,Length_song_playing,Status},Check_fresh_song}
												
									end
								end,
							0,Accum_State),
						case Check_fresh_song_status > 0 of 
							true ->
								{Process_tracks,New_timestamp};
							false ->
								io:format("~nfresh track identified is ~p",[Artist_name_ets]),
								New_process_tracks = [{Id_song_ets,New_timestamp,0,fresh} | Process_tracks ],
								{New_process_tracks,New_timestamp}
						end
				end,
			{State_data,Timestamp_data},Ets_results),
			Process_accum_end
	end.


get_duration_audio_wav(File_path)->
	{ok, Audio_binary} = file:read_file(File_path),
	<<_:4/binary,ChunkSize:32/integer-little,_:4/binary,_:4/binary,_:32/integer-little,_:16/integer-little,
	  _:16/integer-little,_:32/integer-little,ByteRate:32/integer-little,_/binary>> = Audio_binary,
	TotalSeconds = floor(ChunkSize/ByteRate),
	Minutes = floor(TotalSeconds/60),
	Seconds = TotalSeconds rem 60,
	[{minutes,Minutes},{seconds,Seconds},{total_seconds,TotalSeconds}].


get_audio_parts_wav(File_path)->
	{ok, Audio_binary} = file:read_file(File_path),
	<<Chunk_id:4/binary,ChunkSize:32/integer-little,Format:4/binary,Subchunkid:4/binary,Subcsize:32/integer-little,Audio_format:16/integer-little,
	  Number_channels:16/integer-little,SamplesPerSecond:32/integer-little,ByteRate:32/integer-little,BlockAlign:16/integer-little,BitsPerSample:16/integer-little,
	  SubChunkTwo_id:4/binary,ChunkTwoSize:32/integer-little,PcmData:ChunkTwoSize/binary
	  ,_/binary>> = Audio_binary,
	[{chunk_id,Chunk_id},{chunk_size,ChunkSize},{format,Format},{subchunkid,Subchunkid},{subchunksize,Subcsize},{audio_format,Audio_format},
	 {number_channels,Number_channels},{samplespersecond,SamplesPerSecond},{byterate,ByteRate},{blockalign,BlockAlign},{bitspersample,BitsPerSample},
	 {subchunktwoid,SubChunkTwo_id},{chunktwosize,ChunkTwoSize},{pcm_data,PcmData}
	].

