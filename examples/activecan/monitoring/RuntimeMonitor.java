package monitoring;

import java.util.ArrayList;
import org.apache.log4j.Logger;
import org.objectweb.proactive.api.PAActiveObject;
import org.objectweb.proactive.core.util.log.Loggers;
import org.objectweb.proactive.core.util.log.ProActiveLogger;

public class RuntimeMonitor {
	static Logger logger = ProActiveLogger.getLogger(Loggers.EXAMPLES);
	
	// lists of names of peers that are in an accepting or bad state, resp.
	private ArrayList<String> acceptingstate = new ArrayList<String>();
	private ArrayList<String> badstate = new ArrayList<String>();
	
	public RuntimeMonitor() {
	}
	
	public void clientConnected() {
		System.out.println("INFO: a client has just connected!");
	}
	
	public boolean isInAnAcceptingState() {
		return this.acceptingstate.size() > 0;
	}
	
	public boolean isInABadState() {
		return this.badstate.size() > 0;
	}
	
	public void accepting(String peername) {
		System.out.println("INFO: the peer '" + peername + "' discovered a violation of its assumptions (on the environment).");
		acceptingstate.add(peername);
	}
	
	public void bad(String peername) {
		System.out.println("INFO: the peer '" + peername + "' discovered a violation of its commitments (to the environment).");
		badstate.add(peername);
	}
	
	public static void main(String[] args) {
		try {
			RuntimeMonitor monitor = (RuntimeMonitor)PAActiveObject.newActive(RuntimeMonitor.class.getName(), null);
			PAActiveObject.registerByName(monitor, "globalstate");
			logger.info("INFO: monitoring Active Object registered!");
		} catch (Exception ex) {
			logger.info("ERROR: could not create and register the monitoring active object.");
		}
	}
}
