package banking;

import java.io.Serializable;
import java.util.Optional;
import java.util.Random;

public class Account implements Serializable {
	double balance;
	String code;
	boolean loggedIn;
	String name;
	
	public Account(String code, String name, double balance) {
		this.balance = balance;
		this.code = code;
		this.loggedIn = false;
		this.name = name;
	}
	
	public boolean login(String code) {
		if (!this.loggedIn && this.code.equals(code)) {
			this.loggedIn = true;
			return true;
		} else {
			return false;
		}
	}
	
	public void logout() {
		this.loggedIn = false;
	}
	
	public void deposit(double amount) {
		this.balance += amount;
	}
	
	public String getName() {
		return this.name;
	}
}
