import java.io.Serializable;

public class Hello implements Serializable {
	
	public Hello() {
	}
	
	public String sayhello() {
		System.out.println("Someone called 'sayhello'");
		return "Hello from the server!";
	}
}
