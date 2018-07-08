To run the ActiveCAN verification case study, please follow the following steps:

1. First make sure that the StaRVOOrS tool is working (from the root directory of this repository). The current set-up is tested on MacOS (High Sierra), but it might be good to rebuild StaRVOOrS. Instructions for this can be found at: https://github.com/starvoors/StaRVOOrS-tool.

2. Run the command './compileall.sh' on the console. This will generate and runtime monitors for a set-up with two clients (and a centralised monitor).

3. Open three different console windows. Then do the following:
	- In the first console window, run './monitor.sh monitor' and wait for the runtime monitor to be fully initialised
	- In the second window, run './run.sh client1' and wait for the "Bank Menu" to appear
	- In the third window, run './run.sh client2' and again wait for the "Bank Menu" to appear. After this, the first console window should print that two clients have connected.
	
4. From the two client console windows, you can now create new ActiveCAN peers, new ActiveCAN networks, connect peers to networks and perform lookup and insert queries over a network.