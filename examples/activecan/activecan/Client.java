package activecan;

import org.apache.log4j.Logger;
import org.objectweb.proactive.api.PAActiveObject;
import org.objectweb.proactive.api.PAFuture;
import org.objectweb.proactive.core.util.log.Loggers;
import org.objectweb.proactive.core.util.log.ProActiveLogger;
import org.objectweb.proactive.core.util.wrapper.BooleanWrapper;
import org.objectweb.proactive.core.util.wrapper.StringMutableWrapper;
import java.net.UnknownHostException;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.Serializable;
import java.util.HashMap;
import java.util.List;
import java.util.LinkedList;
import java.util.Map;
import java.util.Random;

public class Client {
	static BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
  static Logger logger = ProActiveLogger.getLogger(Loggers.EXAMPLES);
	
  public static final int CORNER_TO_CORNER = 1;
  public static final int CORNER_TO_THREE_CORNERS = 3;
  public static final int TWO_CORNERS_TO_ALL = 0;
	
	Map<String, Peer> localpeers = new HashMap<String, Peer>();
	
	public String readString() {
		try {
			return br.readLine();
		} catch (Exception ex) {
			ex.printStackTrace();
		}
		return "";
	}
	
	public static int readInt() {
		try {
			return Integer.parseInt(br.readLine());
		} catch (Exception ex) {
			ex.printStackTrace();
		}
		return -1;
	}
	
	public static void write(String text) {
		System.out.println(text);
	}
	
	private void createPeer(String name) {
		boolean register = false;
		Peer peer = null;
		
		try {
			peer = (Peer)PAActiveObject.newActive(Peer.class.getName(), new Object[] { name });
			logger.info("New peer named '" + name + "' has been created");
			write("New peer has been created");
			register = true;
		} catch (Exception ex) {
			logger.info("New peer named '" + name + "' could not be created!");
			write("New peer could NOT be created!");
		}

		if (register) {
			try {
				PAActiveObject.registerByName(peer, name);
				logger.info("Peer has been registered at '//localhost/" + name + "'");
				write("New peer has been registered at '//localhost/" + name + "'");
				localpeers.put(name, peer);
			} catch (Exception ex) {
				logger.info("New peer could NOT be registered!");
				write("New peer could NOT be registered!");
			}
		}
	}
	
	private void menuCreatePeer() {
		write("Name of the peer:");
		String name = readString();
		
		if (name.length() == 0) {
			write("Error: name cannot be empty!");
		} else if (localpeers.containsKey(name)) {
			write("Error: name has already locally been taken!");
		} else {
			createPeer(name);
		}
	}
	
	private void joinPeer(String from, String to) {
		if (!localpeers.containsKey(from)) {
			write("Error: the source peer has not been locally registered");
			return;
		}
		
		Peer local = localpeers.get(from);
				
		try {
			Peer remote = (Peer)PAActiveObject.lookupActive(Peer.class.getName(), "//localhost/" + to);
			write("INFO - connected to the remote peer (at //localhost/" + to + ")");
			BooleanWrapper result = local.join(remote);
			write("Connecting to the remote peer........");
			PAFuture.waitFor(result);
			write("Connected to the remote peer!");
		} catch (Exception ex) {
			write("Error: could not connect to the remote peer!");
		}
	}
	
	private void menuJoinPeer() {
		write("Name of the (local) source peer");
		String from = readString();
		write("Name of the target peer to join");
		String to = readString();
		joinPeer(from, to);
	}
	
	private void menuRandomLookups() {
		write("Name of the peer that performs the lookups");
		String peer = readString();
		write("Number of random lookups to perform:");
		int amount = readInt();
		randomLookups(peer, amount);
	}
	
	private void menuRandomInserts() {
		write("Name of the peer that performs the inserts");
		String peer = readString();
		write("Number of random inserts to perform:");
		int amount = readInt();
		randomInserts(peer, amount);
	}
	
	private void createNetwork() {
		write("Name of the peer:");
		String name = readString();
		
		if (!localpeers.containsKey(name)) {
			write("Error: name has already locally been taken!");
			return;
		}
		
		Peer peer = localpeers.get(name);
		peer.createNetwork();
		write("Network is created for peer '" + name + "'; other peers can now connect to it!");
	}
	
	public void menu() {
		while (true) {
			write("**** BANK MENU ****");
			write("1. create peer");
			write("2. create network");
			write("3. connect peers");
			write("4. perform random lookups");
			write("5. perform random inserts");

			switch (readInt()) {
				case 1 : menuCreatePeer(); break;
				case 2 : createNetwork(); break;
				case 3 : menuJoinPeer(); break;
				case 4 : menuRandomLookups(); break;
				case 5 : menuRandomInserts(); break;
			}
		}
	}
	
	private List<Key> generatekeys(int amount) {
		List<Key> keys = new LinkedList<Key>();
		Random r = new Random();
		
		for (int i = 0; i < amount; i++) {
			int x = Math.abs(r.nextInt()) % Zone.MAX_X;
			int y = Math.abs(r.nextInt()) % Zone.MAX_Y;
			keys.add(new Key(x, y));
		}
		
		return keys;
	}
	
	private void randomLookups(String peername, int amount) {
		write("Receiving peer information....");
		
		if (!localpeers.containsKey(peername)) {
			write("Error: the source peer has not been locally registered!");
			return;
		}
		
		Peer peer = localpeers.get(peername);
		
		write("Generating keys....");
		List<Key> keys = generatekeys(amount);
		
		write("Lookup the value for each key...");
		List<Object> values = new LinkedList<Object>();
    for (Key k : keys) {
			values.add(peer.lookup(k));
    }

		write("Waiting for all lookups to complete...");
		PAFuture.waitForAll(values);
		
		write("All random lookups have been performed!");
	}
	
	private void randomInserts(String peername, int amount) {
		write("Receiving peer information....");
		
		if (!localpeers.containsKey(peername)) {
			write("Error: the source peer has not been locally registered!");
			return;
		}
		
		Peer peer = localpeers.get(peername);
		
		write("Generating keys....");
		List<Key> keys = generatekeys(amount);
		
		write("Generating values....");
    List<Zone> msg = new LinkedList<Zone>();
		int msgsize = 24;
    for (int z = 0; z < msgsize; z++) {
			msg.add(new Zone((int)(z), (int)(z), (int)(z), (int)(z), null));
    }
		
		write("Adding key/value pairs to the distributed hash table....");
    for (Key k : keys) {
			peer.add(k, (Serializable)msg);
    }
		
		write("All random inserts have been performed!");
	}
	
	public void initialise() {
		// ...
	}
	
	public static void main(String[] args) {
		Client client = new Client();
		client.initialise();
		client.menu();
	}
}
