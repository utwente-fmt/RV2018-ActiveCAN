import org.apache.log4j.Logger;
import org.objectweb.proactive.api.PAActiveObject;
import org.objectweb.proactive.core.util.log.Loggers;
import org.objectweb.proactive.core.util.log.ProActiveLogger;

public class Client {
  static Logger logger = ProActiveLogger.getLogger(Loggers.EXAMPLES);

  public static void main(String[] args) {
		try {
			// get reference to AO of the server
			Hello hello = (Hello)PAActiveObject.lookupActive(Hello.class.getName(), "//localhost/hello");
			
			// call method 'sayHello' on the servers' AO and print result
      String response = hello.sayhello();
      logger.info("INFO: the message '" + response + "' was received on the client");
			
		} catch (Exception e) {
			logger.info("ERROR: could not connect to remote active object!");
		}
  }
}
