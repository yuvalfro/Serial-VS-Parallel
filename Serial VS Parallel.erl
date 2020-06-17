%%%-------------------------------------------------------------------
%%% @author Yuval Froman
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. Jun 2020 15:32
%%%-------------------------------------------------------------------
-module('Serial VS Parallel').
-author("Yuval Froman").

%% API
-export([ring_parallel/2, ring_serial/2, mesh_parallel/3,mesh_serial/3]).

%%---------------------------------- ring_parallel function - Create a circle of processes --------------------------------------------------------
%% N - Number of processes
%% M - Number of messages to send
%% PID1 generate M messages and transmitted through the circle until they rich PID1. After PID1 receive the Mth message the function is finish
%% The function of each process is the next process, this is how we create the circle

ring_parallel(N,_) when (N =< 0) or (not is_integer(N)) -> io:format("Number of processes should be a positive integer!~n");   % N is not positive integer
ring_parallel(_,M) when (M =< 0) or (not is_integer(M)) -> io:format("Number of messages should be a positive integer!~n");    % M is not positive integer
ring_parallel(N,M) ->
  StartTime = os:system_time(microsecond),                                                                 % Start time
  MainPRS = self(),
  register(pid1,spawn(fun() -> createPIDX(N,N,M,StartTime,MainPRS) end)),                                  % Create the first PID
  receive                                                                                                  % Receive for the main process - for printing the result
    Result -> Result
  end.

%% Creating the circle
createPIDX(0,N,M,StartTime,MainPRS) ->                                                                      % Finish create circle
  %io:format("Sending ~p messages ~n",[M]),
  sendMsg(pid1,N,1,M,StartTime,MainPRS),                                                                    % The first PID generate M messages
  processReceiveMSGN(pid1,M);

createPIDX(K,N,M,StartTime,MainPRS) ->
  PIDX = spawn(fun() -> createPIDX(K-1,N,M,StartTime,MainPRS) end),                                         % Create PID number X
  processReceiveMSGN(PIDX,M).                                                                               % Receive for PID number X

%%--------------------------------------------------------------------------------------------------------------------------------------------------

%%---------------------------------- ring_serial function - Create a circle with one processes -----------------------------------------------------
%% V - Number of vertices
%% M - Number of messages to send
%% PID generate M messages and transmitted through the circle until they rich PID. After PID receive the Mth message the function is finish

ring_serial(V,_) when (V =< 0) or (not is_integer(V)) -> io:format("Number of processes should be a positive integer!~n");    % N is not positive integer
ring_serial(_,M) when (M =< 0) or (not is_integer(M)) -> io:format("Number of messages should be a positive integer!~n");     % M is not positive integer
ring_serial(V,M) ->
  StartTime = os:system_time(microsecond),                                                                  % Start time
  MainPRS = self(),
  register(pid,spawn(fun() -> processReceiveMSGV(pid,V,M,StartTime,MainPRS) end)),                          % Create process
  %io:format("Sending ~p messages ~n",[M]),
  pid ! {"MSG",1,1},                                                                                        % Send the first message
  receive                                                                                                   % Receive for the main process - for printing the result
    Result -> Result
  end.
%%--------------------------------------------------------------------------------------------------------------------------------------------------

%%---------------------------------- send and receive functions ------------------------------------------------------------------------------------

%% Send M messages from PID and also receive
sendMsg(PID,N,K,M,StartTime,MainPRS) ->
  %io:format("Sending message number ~p~n",[K]),
  PID ! {"MSG",K},                                                            % Send message
  receive
    {"MSG",M} ->                                                              % Received the last message
      %io:format("Finish sending all the messages! ~n"),
      TotalTime = os:system_time(microsecond)-StartTime,
      io:format("Total Time of action: ~p microseconds~n",[TotalTime]),
      MainPRS ! {TotalTime, M, M};                                            % Print {Total time, Number of messages sent, Number of messages received}
    {"MSG",K} ->                                                              % Received message number K<M so send another one
      sendMsg(PID,N,K+1,M,StartTime,MainPRS);
    Error ->
      io:format("Error: ~p~n",[Error])
  end.

%% Receive for each process
processReceiveMSGN(PIDX,M) ->
  receive
    {"MSG",M} ->                                                              % Last message
      %io:format("Process ~p transmit message number ~p and terminated~n",[self(),M]),
      PIDX ! {"MSG", M};                                                      % Pass message
    {"MSG",K} ->                                                              % Not the last message
      %io:format("Process ~p transmit message number ~p~n",[self(),K]),
      PIDX ! {"MSG", K},                                                      % Pass message
      processReceiveMSGN(PIDX,M);
    Error ->
      io:format("Error: ~p~n",[Error])
  end.

%% Receive for one process
processReceiveMSGV(PID,V,M,StartTime,MainPRS) ->
  receive
    {"MSG",1,K} when K == M+1->                                                 % Vertex number 1, finish sending all the messages
      %io:format("Finish sending all the messages! ~n"),
      TotalTime = os:system_time(microsecond)-StartTime,
      io:format("Total Time of action: ~p microseconds~n",[TotalTime]),
      MainPRS ! {TotalTime, M, M};                                              % Print {Total time, Number of messages sent, Number of messages received}
    {"MSG",V,K} ->                                                              % Vertex number V - end of the circle, start from vertex 1 and number of messages+1
      %io:format("Process ~p transmit message number ~p from vertex number ~p~n",[self(),K,V]),
      PID ! {"MSG",1, K+1},                                                     % Pass message
      processReceiveMSGV(PID,V,M,StartTime,MainPRS);
    {"MSG",R,K} ->                                                              % Middle of the circle - continue to the next vertex
      %io:format("Process ~p transmit message number ~p from vertex number ~p~n",[self(),K,R]),
      PID ! {"MSG",R+1, K},                                                     % Pass message
      processReceiveMSGV(PID,V,M,StartTime,MainPRS);
    Error ->
      io:format("Error: ~p~n",[Error])
  end.

%%--------------------------------------------------------------------------------------------------------------------------------------------------

%%---------------------------------- mesh_serial function - Create a mesh grid of one process ------------------------------------------------------
%% N - Create NxN processes
%% M - Number of messages to send
%% C - Number between 1 to N^2 that defines the master process

mesh_parallel(N,_,_) when (N =< 0) or (not is_integer(N)) -> io:format("Number of processes should be a positive integer!~n");                  % N is not positive integer
mesh_parallel(_,M,_) when (M =< 0) or (not is_integer(M)) -> io:format("Number of processes should be a positive integer!~n");                  % M is not positive integer
mesh_parallel(N,_,C) when (C =< 0) or (C > N*N) or (not is_integer(C))-> io:format("Master process should be an integer between 1 to N^2!~n");  % C is not integer between 1 to N^2
mesh_parallel(N,M,C) ->
  StartTime = os:system_time(microsecond),             % Start time
  register(main,self()),
  createMeshGrid(N, M, C, 1,false,StartTime),          % false = not serial mode
  receive                                              % Receive for the main process - for printing the result
    Result -> _ = killAll(N,C),
      unregister(main),
      Result
  end.

%%--------------------------------------------------------------------------------------------------------------------------------------------------

%%---------------------------------- mesh_serial function - Create a mesh grid of one process ------------------------------------------------------
%% N - Create NxN processes
%% M - Number of messages to send
%% C - Number between 1 to N^2 that defines the master process

mesh_serial(N,_,_) when (N =< 0) or (not is_integer(N)) -> io:format("Number of processes should be a positive integer!~n");                  % N is not positive integer
mesh_serial(_,M,_) when (M =< 0) or (not is_integer(M)) -> io:format("Number of processes should be a positive integer!~n");                  % M is not positive integer
mesh_serial(N,_,C) when (C =< 0) or (C > N*N) or (not is_integer(C))-> io:format("Master process should be an integer between 1 to N^2!~n");  % C is not integer between 1 to N^2
mesh_serial(N,M,C) ->
  StartTime = os:system_time(microsecond),             % Start time
  register(mainPRS,self()),
  register(pid,spawn(fun() -> processReceiveMesh(N, M, C, C, true, StartTime) end)),   % Create process, true = serial mode
  pid ! {"start"},
  receive                                                                              % Receive for the main process - for printing the result
    Result -> unregister(mainPRS),
      Result
  end.

%%--------------------------------------------------------------------------------------------------------------------------------------------------

%% Kill all processes
killAll(N,C) -> killAll(N,C,1).
killAll(N,C,C) ->
  if
    C =:= N*N -> done;
    true -> killAll(N,C,C+1)
  end;
killAll(N,_,Curr) when Curr =:= N*N  -> exit(whereis(getProcessName(Curr)), kill);
killAll(N,C,Curr) -> exit(whereis(getProcessName(Curr)),kill), killAll(N,C,Curr+1).

%% Creating the mesh grid
createMeshGrid(N, _, C, Curr,_,_) when Curr =:= N*N + 1 ->      % Finish creating the mesh grid, start sending messages
  getProcessName(C) ! {"start"};                                % Master process (number C) sending the messages
% otherwise keep creating the grid processes
createMeshGrid(N, M, C, Curr,IsSerial,StartTime) ->             % Create process number i, register him as 'pidi'
  register(getProcessName(Curr), spawn(fun() -> processReceiveMesh(N,M,C,Curr,IsSerial,StartTime) end)),
  createMeshGrid(N, M, C, Curr+1,IsSerial,StartTime).

%% Receive for each process
processReceiveMesh(N, M, C, CurrNode, IsSerial,StartTime) ->
  receive
  % Message received
    {SenderNode, MsgIndex, MsgType}->
      msgBroker(get(getMsgName(SenderNode,MsgIndex,MsgType,CurrNode)), {SenderNode,MsgIndex,MsgType}, N, C, M, CurrNode, IsSerial,StartTime);

  % start sending M messages after creating the grid
    {"start"} ->
      put("totalMsgs",0),                           % Put in the main process dictionary number of sent messages
      put("responses",0),                           % Put in the main process dictionary number of received messages
      sendMsgMesh(N, M, C, IsSerial,StartTime),     % Start sending M messages from C
      if
        IsSerial -> erase();                                           % IsSerial = true: erase main process dictionary
        true -> processReceiveMesh(N, M, C, C, IsSerial, StartTime)    % IsSerial = false: keep receiving messages
      end
  end.

%%---------------------------------- send message functions ---------------------------------------------------------------------------------

%% Send M messages from C
sendMsgMesh(N, M, C, IsSerial,StartTime) ->
  sendMsgMesh(N, M, C, 1, IsSerial,StartTime).

%% The last message
sendMsgMesh(N, M, C, M, IsSerial,StartTime) ->
  put(getMsgName(C, M, "receive", C), 0),                           % Register this message with default value 0
  sendNeighbors(C, N, M, "receive", C, IsSerial, M, C,StartTime);   % Send message to all neighbors

% if MsgIndex < M keep sending messages from C
sendMsgMesh(N, M, C, MsgIndex, IsSerial,StartTime) ->
  put(getMsgName(C, MsgIndex, "receive", C), 0),                           % Register this message with default value 0
  sendNeighbors(C, N, MsgIndex, "receive", C, IsSerial, M, C,StartTime),   % Send message to all neighbors
  sendMsgMesh(N, M, C, MsgIndex + 1, IsSerial,StartTime).                  % Send the next message


%% Sending message to all neighbors of CurrNode: {SenderNode,MsgIndex,MsgType}
sendNeighbors(CurrNode, N, MsgIndex, MsgType, SenderNode, IsSerial, M, C,StartTime) ->
  {I, J} = node2Point(CurrNode, N),
  sendNeighbor(point2Node(I, J+1, N), N, MsgIndex, MsgType, SenderNode, IsSerial, M, C, StartTime), % Sending message up
  sendNeighbor(point2Node(I, J-1, N), N, MsgIndex, MsgType, SenderNode, IsSerial, M, C, StartTime), % Sending message down
  sendNeighbor(point2Node(I+1, J, N), N, MsgIndex, MsgType, SenderNode, IsSerial, M, C, StartTime), % Sending message right
  sendNeighbor(point2Node(I-1, J, N), N, MsgIndex, MsgType, SenderNode, IsSerial, M, C, StartTime). % Sending message left

%% Serial mode - the process send to itself
sendNeighbor(CurrNode, N, MsgIndex, MsgType, SenderNode, true, M, C, StartTime) when CurrNode >= 1, CurrNode =< N*N ->
  pid ! {SenderNode,MsgIndex,MsgType},
  processReceiveMesh(N, M, C, CurrNode, true, StartTime);

%% Parallel mode - sending message to specific neighbor if it exist
sendNeighbor(CurrNode, N, MsgIndex, MsgType, SenderNode, false, _, _,_) when CurrNode >= 1, CurrNode =< N*N ->
  case whereis(getProcessName(CurrNode)) of                % Check if this process still alive
    undefined -> error_invalid_ProcessName;
    PID -> PID ! {SenderNode, MsgIndex, MsgType}
  end;

sendNeighbor(_,_,_,_,_,_,_,_,_) -> invalid_CurrNode.

%%--------------------------------------------------------------------------------------------------------------------------------------------------

%%---------------------------------- more internal functions ---------------------------------------------------------------------------------------

%% point(i,j) when i = 0 to N-1 , Node = 1 to N^2
point2Node(I, J, N) -> I*N + J+1.
node2Point(Node, N) -> {(Node-1) div N , (Node-1) rem N}.

%% Return a name represent a process with the index 'Index'
%% Used later to register the PID with this name
getProcessName(Index) -> list_to_atom("pid" ++ integer_to_list(Index)).

%% Convert message index and MsgType to list to be registered in the process dictionary
getMsgName(_, MsgIndex, "receive", CurrNode) ->
  integer_to_list(CurrNode) ++ " receive " ++ integer_to_list(MsgIndex);

getMsgName(SenderNode, MsgIndex, "response", CurrNode) ->
  integer_to_list(CurrNode) ++ " got response from " ++ integer_to_list(SenderNode) ++ " on " ++ integer_to_list(MsgIndex).

%%--------------------------------------------------------------------------------------------------------------------------------------------------

%%---------------------------------- message broker functions --------------------------------------------------------------------------------------

%% Response: Current process is C
msgBroker(undefined,{SenderNode,MsgIndex,"response"},N,C,M,C,IsSerial,StartTime) ->
  put("totalMsgs", get("totalMsgs")+1),                                            % Increase the total number of messages
  put(getMsgName(SenderNode,MsgIndex,"response",C),0),                             % Register message with a default value of 0
  put("responses", get("responses")+1),                                            % Increase the total number of response messages
  TotalResponses = M*((N*N)-1),
  case get("responses") of
    TotalResponses ->
      TotalTime = os:system_time(microsecond)-StartTime,
      io:format("Total Time of action: ~p microseconds~n",[TotalTime]),            % End of process, print time of action
      if
        IsSerial -> mainPRS ! {TotalTime,M,TotalResponses};
        true -> main ! {TotalTime,M,TotalResponses}
      end;
    _ ->
      if
        IsSerial -> break;
        true -> processReceiveMesh(N, M, C, C, IsSerial, StartTime)                % Parallel mode - keep receiving
      end
  end;

%% Response: Current process isn't C
msgBroker(undefined,{SenderNode,MsgIndex,"response"},N,C,M,CurrNode,IsSerial,StartTime) ->
  put(getMsgName(SenderNode,MsgIndex,"response",CurrNode),0),                               % Register message with a default value of 0
  sendNeighbors(CurrNode,N,MsgIndex,"response",SenderNode, IsSerial, M, C,StartTime),       % Send message to neighbors
  if
    IsSerial -> break;
    true ->   processReceiveMesh(N, M, C, CurrNode,IsSerial,StartTime)                      % Parallel mode - keep receiving
  end;


%% Receive: Pass it to the neighbors and send response
msgBroker(undefined,{SenderNode,MsgIndex,"receive"},N,C,M,CurrNode,IsSerial,StartTime) ->
  put(getMsgName(SenderNode,MsgIndex,"receive",CurrNode),0),                            % Register message with a default value of 0
  sendNeighbors(CurrNode,N,MsgIndex,"receive",SenderNode, IsSerial, M, C, StartTime),   % Send message to neighbors
  put(getMsgName(SenderNode,MsgIndex,"response",CurrNode),0),                           % Register message with a default value of 0
  sendNeighbors(CurrNode,N,MsgIndex,"response",CurrNode, IsSerial, M, C, StartTime),    % Send message to neighbors
  if
    IsSerial -> break;
    true ->   processReceiveMesh(N, M, C, CurrNode, IsSerial, StartTime)                % Parallel mode - keep receiving
  end;

%% Receive: already received this message in this process
msgBroker(_,_,N,C,M,CurrNode,IsSerial,StartTime) ->
  if
    CurrNode =:= C ->  put("totalMsgs", get("totalMsgs")+1);
    true -> pass
  end,
  if
    IsSerial -> break;
    true -> processReceiveMesh(N, M, C, CurrNode, IsSerial, StartTime)
  end.

%%--------------------------------------------------------------------------------------------------------------------------------------------------

