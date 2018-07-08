import org.apache.log4j.Logger;
import org.objectweb.proactive.api.PAActiveObject;
import org.objectweb.proactive.core.util.log.Loggers;
import org.objectweb.proactive.core.util.log.ProActiveLogger;

public class Server  {
	static Logger logger = ProActiveLogger.getLogger(Loggers.EXAMPLES);

	public static void main(String[] args) {
		try {
			// create and register a new active object
			Hello hello = (Hello)PAActiveObject.newActive(Hello.class.getName(), null);
			PAActiveObject.registerByName(hello, "hello"); // localhost/hello
			logger.info("INFO - the active object has been created");
			
			// call method 'sayHello' on active object and print response
			String response = hello.sayhello();
			logger.info("INFO - the active object responds with '" + response + "'");
			
		} catch (Exception ex) {
			logger.info("ERROR - could not create and register the active object!");
		}
	}
}
