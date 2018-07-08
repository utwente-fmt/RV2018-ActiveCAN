package banking;

import org.apache.log4j.Logger;
import org.objectweb.proactive.api.PAActiveObject;
import org.objectweb.proactive.core.util.log.Loggers;
import org.objectweb.proactive.core.util.log.ProActiveLogger;
import java.io.BufferedReader;
import java.io.InputStreamReader;

public class Client {
	static BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
  static Logger logger = ProActiveLogger.getLogger(Loggers.EXAMPLES);
	
	Bank bank;
	
	public Client(Bank bank) {
		this.bank = bank;
	}
	
	public void initialised() {
		//...
	}
	
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
	
	public static double readDouble() {
		try {
			return Double.parseDouble(br.readLine());
		} catch (Exception ex) {
			ex.printStackTrace();
		}
		return -1.0;
	}
	
	public static void write(String text) {
		System.out.println(text);
	}
	
	private boolean login() {
		write("Name: ");
		String name = readString();
		write("Pincode: ");
		String code = readString();
		return bank.login(name, code);
	}
	
	private void logout() {
		write("Name: ");
		String name = readString();
		bank.logout(name);
	}
	
	private void deposit() {
		write("Name: ");
		String name = readString();
		write("Amount: ");
		double amount = readDouble();
		bank.deposit(name, amount);
	}
	
	public void menu() {
		while (true) {
			write("**** BANK MENU ****");
			write("1. login");
			write("2. logout");
			write("3. deposit");
			
			switch (readInt()) {
				case 1 : if (login()) { write("login successful"); break; } else { write("login unsuccessful"); break; }
				case 2 : logout(); break;
				case 3 : deposit(); break;
			}
		}
	}

  public static void main(String[] args) {
		try {
			// connect to the bank Active Object
			Bank bank = (Bank)PAActiveObject.lookupActive(Bank.class.getName(), "//localhost/bank");
			logger.info("Connected with the bank");
			
			// enter the client interface of the bank
			Client client = new Client(bank);
			client.initialised();
			client.menu();
		}
		catch (Exception e) {
			logger.info("Error: could not connect to remote active object");
		}
  }
}
