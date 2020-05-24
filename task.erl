-module(task).
-compile(export_all).


%It represents a “parent process” that takes a predicate function P and a list L as arguments.
%The function applies a concurrent filtering: it spawns as many processes as the number of elements
%of the list. Each process evaluates the predicate function on an element of the list and answers to
%its parent process whether the result of function P is true or false. The parent process puts the element
%into the result list if function P evaluated to true.


%"My name is Anna Try THIS out"
%"MATTHIS
% task:pfilt(fun(E)-> (E>$i) end,"My name is Anna Try THIS out").
%lists:filter(P,L).

start(NWorkers)-> global:register_name(task, spawn(fun()-> init(NWorkers) end)).

init(NWorkers)->
	process_flag(trap_exit,true),
  WorkerPids = lists:map(fun(_) -> spawn(fun() -> workers() end) end, NWorkers),
	InitState= {NUsers,#{}},
	loop(WorkerPids, InitState).

loop(WorkerPids, JobList)->
		receive
			stop -> io:format("Server is Done for good! ~n"),
      kill_processes(Pids);

      {free, Pid} -> io:format("Server got free ~p", [Pid]);

      {login,UPid,UName} -> NState= handleLogin(State,UPid,UName),
								 loop(NState);

      {msg,UPid,Msg} -> NState= handleMsg(State,UPid,Msg),
								loop(NState)
		end.


pfilt(P, L) ->
      MyPid = self(),
      WorkerPids = lists:map(fun(H) -> spawn( fun() -> applyFunction(MyPid, P, H) end) end, L),
      lists:flatten(gather(WorkerPids)).


applyFunction(MyPid, P, L) ->
        %io:format("List elemet: ~p ", [L]),
        MyPid ! {self(), lists:filter(P,[L])}.


gather([]) -> [];
gather([H|T]) ->
    receive
        {H, Ret} -> [Ret | gather(T)];
        {H, []} -> gather(T)
    end.

decompress([])->[];
decompress([H|T])->constr(H)++decompress.

compress([])->[];
compress([H])-> [{count(H,[H]),H}];
compress([H|T])->[{count(H,T)+1,H}|compress(delete_occ(H,T))].

constr({0,_Element})-> [];
constr({Times,Element}) -> [Element|constr({Times-1,Element})].

count(_E,[])->0;
count(E,[E|T])-> 1+ count(E,T);
count(E,[_H|T])->  count(E,T).

delete_occ(_E,[])->[];
delete_occ(E,[E|T]) -> delete_occ(E,T);
delete_occ(E,[H|T])-> [H|delete_occ(E,T)].

kill_processes([]) -> ok;
kill_processes([HP|TP]) -> exit(HP,killed), kill_processes(TP).
