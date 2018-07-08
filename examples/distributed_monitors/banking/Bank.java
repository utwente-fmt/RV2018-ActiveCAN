package banking;

import java.util.ArrayList;
import java.util.Optional;

public class Bank {
	ArrayList<Account> accounts = new ArrayList<Account>();
	
	public Bank() {
	}
	
	public Bank(ArrayList<Account> accounts) {
		this.accounts = accounts;
	}
	
	public boolean login(String name, String code) {
		for (int i = 0; i < accounts.size(); i++) {
			if (accounts.get(i).getName().equals(name)) {
				return accounts.get(i).login(code);
			}
		}
		return false;
	}
	
	public void logout(String name) {
		for (int i = 0; i < accounts.size(); i++) {
			if (accounts.get(i).getName().equals(name)) {
				accounts.get(i).logout();
			}
		}
	}
	
	public void deposit(String name, double amount) {
		for (int i = 0; i < accounts.size(); i++) {
			if (accounts.get(i).getName().equals(name)) {
				accounts.get(i).deposit(amount);
			}
		}
	}
}
