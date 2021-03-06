/*
 * ################################################################
 *
 * ProActive Parallel Suite(TM): The Java(TM) library for
 *    Parallel, Distributed, Multi-Core Computing for
 *    Enterprise Grids & Clouds
 *
 * Copyright (C) 1997-2012 INRIA/University of
 *                 Nice-Sophia Antipolis/ActiveEon
 * Contact: proactive@ow2.org or contact@activeeon.com
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Affero General Public License
 * as published by the Free Software Foundation; version 3 of
 * the License.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
 * USA
 *
 * If needed, contact us to obtain a release under GPL Version 2 or 3
 * or a different license than the AGPL.
 *
 *  Initial developer(s):               The ProActive Team
 *                        http://proactive.inria.fr/team_members.htm
 *  Contributor(s):
 *
 * ################################################################
 */

package activecan;

import java.io.Serializable;

/**
 * A class that represents the key. It maps to a unique coordinate in the CAN space.
 * @author The ProActive Team
 */
public class Key implements Serializable { 
    private int x, y;

    public Key(int x, int y) {
        super();
        this.x = x;
        this.y = y;
    }

    public int getCoordY() {
        return y;
    }

    public int getCoordX() {
        return x;
    }

    @Override
    public boolean equals(Object obj) {
        if (obj instanceof Key) {
            return x == ((Key) obj).x && y == ((Key) obj).y;
        }

        return false;
    }

    @Override
    public int hashCode() {
        return x * y;
    }

    @Override
    public String toString() {
        return "Key (" + x + "," + y + ")";
    }
}
