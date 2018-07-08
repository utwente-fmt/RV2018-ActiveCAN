package main;

public class Client {
  public static void main(String[] args) {
		Hello hello = new Hello();
		
		// this should work
		//hello.setValue(2);
		hello.go(2);
		
		// however, this should not, as it violates the Hoare-triple in the contract
		//hello.setValue(2);
		//hello.go();
  }
}
