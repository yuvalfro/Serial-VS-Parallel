# Serial-VS-Parallel
Exercise number 5 in Concurrent and Distributed Programming course.

In this exercise we compare between sequential and parallel erlang. 
The program has 4 functions:
1. ring parallel: Creates a circle of N procesees. M messages are generated by the process P1 and transmitted through the circle 
   until they rich P1 again.

2. ring serial: Same as ring parallel, but use only 1 process.

3. mesh parallel: create a mesh grif of NxN processes. C is the master process (C is a number from 1 to N^2). C generates M messages and 
   spread them to all nodes in the mesh.
   
4. mesh serial: Same as mesh parallel, but use only 1 process.
