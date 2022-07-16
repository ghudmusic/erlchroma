-module(erlchroma_port).

-export([]).

-export([start/0,check_multiple/2,start/1, stop/1, init/1,decode_batch/0]).


%% @doc 
%% 1  write code to decode media file into a pcm format
%% 	  code to then create fingreprint
%%	  code to store fingerprints in binary file/code to also load fingerprints into ets file
%% 	  code to then store in ets along with pseudo id of artist
%% 2. code to then be finding songs as i stream the data from a url and calculate length of song which is being played/streamed
%%	  calculation is done by finding songs which are being played and then using the timestamp to increase  duration of track 





%% @doc

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
    end,Directlist).





%% @doc for testing for running multiple instances of a command 
%%Command = "fpcalc -ts -chunk 2 -overlap -json http://yfm1079accra.atunwadigital.streamguys1.com/yfm1079accra",
-spec check_multiple(integer(),binary()|string())->list().
check_multiple(N,Command)->
	List_pids = lists:map(fun(_) -> start(Command) end,lists:seq(1,N)).


%% @doc for starting the port command
-spec start()->error_no_prog_specified | pid().
start() ->
    error_no_prog_specified.


start(ExtPrg) ->
    spawn(?MODULE, init, [ExtPrg]).


%% @doc for stopping the port program
-spec stop(pid())-> stop.
stop(Pid) ->
    Pid ! stop.


%%for initilizing the port for runnig commands
-spec init([string() | char()]) -> pid().
init(ExtPrg) ->
    process_flag(trap_exit, true),
    {ok,Pid,Ospid} = exec:run(ExtPrg, [stdout, stderr,monitor]),
    loop(Pid,Ospid,ExtPrg).


%%for looping and execting main function
-spec loop(pid(),integer(),[string() | char()]) -> pid().
loop(Pid,Ospid,ExtPrg) ->
    receive
		{'DOWN',Ospid,process,Pid,normal}->
			io:format("~n os process ~p with process ~p is down ~n",[Ospid,Pid]),
			start(ExtPrg);
		{'EXIT', Port, Reason} ->
			io:format("~n Port was killed for reason ~p ~p ~nrestarting port~n",[Port,Reason]),
			exit(processexited);
		Data ->
			io:format("~ndata received is ~p",[Data]),
			loop(Pid,Ospid,ExtPrg)

    end.
