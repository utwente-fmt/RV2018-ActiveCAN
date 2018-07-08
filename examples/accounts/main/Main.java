// [LARVA — Safer Monitoring of Real-Time Java Programs (Tool Paper)]

//https://www.um.edu.mt/library/oar/bitstream/handle/123456789/27802/LARVA_safer_monitoring_of_real_time_Java_programs_tool_paper_2009.pdf?sequence=3&isAllowed=y

package main;

import java.io.BufferedReader;
import java.io.InputStreamReader;

public class Main {
	static BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
	
	public static int read() {
		try {
			return Integer.parseInt(br.readLine());
		}
		catch (Exception ex) {
			ex.printStackTrace();
		}
		return -1;
	}
	
	public static void write(String text) {
		System.out.println(text);
	}
	
	public void menu(Account account) {
		boolean run = true;
		
		while (run) {
			System.out.println("**** MAIN MENU ****");
			System.out.println("1. add user");
			System.out.println("2. delete user");
			System.out.println("3. exit");
			
			switch (read()) {
				case 1 : write("adding a user"); account.addUser(); break;
				case 2 : write("deleting a user"); account.deleteUser(); break;
				case 3 : write("exiting"); run = false; break;
			}
		}
	}
	
	public static void main(String[] args) {
		new Main().menu(new Account());
	}
}
