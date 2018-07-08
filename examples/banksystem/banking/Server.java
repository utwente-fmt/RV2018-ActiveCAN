package banking;

import java.util.ArrayList;
import org.apache.log4j.Logger;
import org.objectweb.proactive.api.PAActiveObject;
import org.objectweb.proactive.core.util.log.Loggers;
import org.objectweb.proactive.core.util.log.ProActiveLogger;

public class Server {
	static Logger logger = ProActiveLogger.getLogger(Loggers.EXAMPLES);
	
    public static void main(String[] args) {
			
			// build a list of bank accounts
			ArrayList<Account> accounts = new ArrayList<Account>();
			accounts.add(new Account("1234", "Wytse", 150.00));
			accounts.add(new Account("5678", "Wolfgang", 250.00));
			
			try {
				// create an Active Object for the bank
				Bank bank = (Bank)PAActiveObject.newActive(Bank.class.getName(), new Object[] { accounts });
				logger.info("Bank Active Object constructed");
				
				// register the bank Active Object
				PAActiveObject.registerByName(bank, "bank"); // localhost/bank
				logger.info("Bank Active Object registered");
			} catch (Exception e) {
				logger.info("Error: could not create and register the active object.");
			}
		}
}