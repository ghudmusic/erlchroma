-module(erlchroma_port).

-export([]).

-export([start/0,check_multiple/2,start/1, stop/1, init/1]).


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
