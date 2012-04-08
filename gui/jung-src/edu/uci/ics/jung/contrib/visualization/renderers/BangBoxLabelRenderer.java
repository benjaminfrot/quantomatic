/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package edu.uci.ics.jung.contrib.visualization.renderers;

import java.awt.Component;
import java.awt.Font;
import javax.swing.JComponent;

/**
 *
 * @author alemer
 */
public interface BangBoxLabelRenderer {

	/**
	 *  Returns the component used for drawing the label.  This method is
	 *  used to configure the renderer appropriately before drawing.
	 *
	 * @param	vv		the <code>JComponent</code> that is asking the
	 *				renderer to draw; can be <code>null</code>
	 * @param	value		the value of the cell to be rendered.  It is
	 *				up to the specific renderer to interpret
	 *				and draw the value.  For example, if
	 *				<code>value</code>
	 *				is the string "true", it could be rendered as a
	 *				string or it could be rendered as a check
	 *				box that is checked.  <code>null</code> is a
	 *				valid value
	 * @param	vertex  the vertex for the label being drawn.
	 */
	<B> Component getBangBoxLabelRendererComponent(JComponent vv, Object value,
						    Font font, boolean isSelected, B bangBox);
}
