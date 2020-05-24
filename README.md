# Short description of the task


Create a distributed solution for an asynchronous filtering server. The server should implement start/1 init/1 stop/0 and loop/2.
The server exposes functions to compress/1 and decompress/1 a list. It also offers a basic client interface filter/2.  
If a connected node calls filter passing a Boolean function and a list, the server will receive a job request, assign it to one of his worker and collect results from the worker.  The worker will call an helper function called pfilt/2  to handle the job, and then it will send back the result. 
Please add a comment with the two shell outputs to prove you run the code as distributed.


## Filter/2
This is the simple client interface to the server. It should take a predicate P and a list L. P is a Boolean function to be used to filter the elements in the list L.    
The client should send a job request to the server containing at least the following data:
1.    A unique identifier to the request
2.    A job including P and the compressed version of L (you have to apply compress/1 to L)
Client must wait for the answer an ACK from the server:
•    If the servers acknowledge the specific referred job, print “job accepted” and wait for the result than prints it (remember to decompress). 
•    If the servers returns a no_reply, it returns ‘server terminated!’ 
•    Otherwise, wait 10 seconds and terminate returning  ‘Server Busy’

## Compress/1
Define the compress function: it counts all repeated elements in a list and packs them together with the number of their occurrences as pairs.
Both server and client will use this function before sending data to each other.
The only standard library function you can use is lists:reverse  and the solution must be using tail recursion.

```
compress(List::list()) -> list()
```
### Some test cases:

```
compress([]) == []
compress("Wwwwhooooooooo?") == [{1,87},{3,119},{1,104},{9,111},{1,63}]
compress("Wwwwhooooooooo?") == [{1, $W},{3, $w},{1, $h},{9, $o}, {1, $?}]
compress("apple") == [{1,97},{2,112},{1,108},{1,101}]
compress([1,1,1,2,2,2,5,4,1,0,1]) == [{3,1},{3,2},{1,5},{1,4},{1,1},{1,0},{1,1}]
``` 
## Decompress/1
 
Define decompress, the inverse operation for the compress/1. This unpack the list of pairs containing elements associated with the number of their occurrences into an uncompressed list.

```
decompress(PairList::list(tuple(int(), term()))) -> list()
```
### Some test cases:

```
decompress([]) == []
decompress([{3,1},{3,2},{1,5},{1,4},{1,1},{1,0},{1,1}]) == [1,1,1,2,2,2,5,4,1,0,1]
decompress([{3,1},{3,2},{1,5}]) == [1,1,1,2,2,2,5]
decompress(compress("apple")) == "apple"
decompress(compress("hohohoooooooooo")) == "hohohoooooooooo"
 ```
 
 ## Start/1 
Create a registered distributed server specifying N workers.

## Init/1 
Instantiate workers and start loop/2.


## Loop/2 
Keeps track of the WorkerPIDs and a JobList. The main task of the loop are:
1.    Whenever a worker among the WorkerPIDs sends a free message, prints “server got free” with the PID of the worker then checks the JobList and assign the first job in it to the worker, removing it from the list. 
2.    Whenever a client sends a job request it saves all important information as an element in the JobList. It prints “server got value” with the job data and sends an ACK to the client. 
3.    If a worker sends back a result the server compresses it and forwards it back to the correct client.
4.    If it receives a stop it kills all workers. It also sends back a no_reply to all the clients whose jobs have not been assigned (Still in JobList). Than it terminates.
 
 
 ## Worker/0
The worker sends a free message to the server and waits to receive a job. The message should be identified univocally so that the server answering it with a job can be recognized. (Otherwise anyone nowing the worker Pid could send jobs).
•    In case the server address is not found it should print: “Worker terminating” and terminate.
•    If it receives a job it should: decompress the list in it (so that it recovers L) apply pfilt/2 to P and L .It should also send back the result to the server and restart itself.
•    If it receives a stop it should print “Worker Killed” with its PID and terminate.


## Pfilt/2
It represents a “parent process” that takes a predicate function P and a list L as arguments. The function applies a concurrent filtering: it spawns as many processes as the number of elements of the list. Each process evaluates the predicate function on an element of the list and answers to its parent process whether the result of function P is true or false. The parent process puts the element into the result list if function P evaluated to true.

```
decompress(fun(term())-> bool() ,  list( term())) -> list()
```


### Some test cases:
```
pfilt(fun(E)-> (E>=$A) and (E<$a) end,"My name is Anna Try THIS out"). 
"MATTHIS"
pfilt(fun(E)-> (E>$i) end,"My name is Anna Try THIS out"). 
"ynmsnnryout"
pfilt(fun(E)-> E>23 end,[1,24,5,55,3,44,2,33,99]).         
[24,55,44,33,99]
```

## Extra
Implement a monitor for the workers, whenever a worker dies the loop/2 will restart a new worker and remove the died one from the WorkerPIDs and substitute with the new worker. 

## Extra
Modify the server to handle different types of jobs so that the worker will apply a different function based on the user request. Instead of filter you will have job/2 specifying also how the worker will handle the job (what to use instead of pfilter).
 
 
 
 ### Example run
 ```
(server@HU-00002750)34> new:start(5).
%%%%%
(client@HU-00002750)6> new:filter(fun(E)-> (E>=$A) and (E<$a) end, "Maaaaaaayyy naaaame isssss Anna"
Job accepted
"MA"
%%%%
server got job {#Fun<erl_eval.7.126501267>,
                [{1,77},  {7,97}, {3,121}, {1,32}, {1,110}, {4,97}, {1,109}, {1,101}, {1,32}, {1,105}, {5,115}, {1,32}, {1,65}, {2,110}, {1,97}]
server got free <0.395.0> 
server got value "MA" 
%%%%%
(client@HU-00002750)7> new:stop().                                              
<8524.389.0>    
%%%%%
(server@HU-00002750)36>
Job server terminating  
Worker terminating <0.398.0> 
Worker terminating <0.395.0> 
Worker terminating <0.396.0> 
Worker terminating <0.400.0> 
Worker terminating <0.399.0>

```
