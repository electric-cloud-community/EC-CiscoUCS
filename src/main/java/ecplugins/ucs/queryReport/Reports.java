
// Reports.java --
//
// Reports.java is part of ElectricCommander.
//
// Copyright (c) 2005-2012 Electric Cloud, Inc.
// All rights reserved.
//

package ecplugins.ucs.queryReport;

import java.util.ArrayList;
import java.util.List;

import com.google.gwt.user.client.ui.Anchor;
import com.google.gwt.user.client.ui.DecoratorPanel;
import com.google.gwt.user.client.ui.Grid;
import com.google.gwt.user.client.ui.HTML;
import com.google.gwt.user.client.ui.Label;
import com.google.gwt.user.client.ui.VerticalPanel;
import com.google.gwt.user.client.ui.Widget;

import com.electriccloud.commander.gwt.client.ComponentBase;
import com.electriccloud.commander.gwt.client.util.CommanderUrlBuilder;

import static com.electriccloud.commander.gwt.client.util.CommanderUrlBuilder.createUrl;

/**
 */
public class Reports
    extends ComponentBase
{

    //~ Static fields/initializers ---------------------------------------------

    /** Renders the component. */
    public static final int MINIMUM_ELEMENTS_PER_ROW = 2;

    //~ Methods ----------------------------------------------------------------

    @Override public Widget doInit()
    {
        DecoratorPanel rootPanel = new DecoratorPanel();
        VerticalPanel  vPanel    = new VerticalPanel();

        vPanel.setBorderWidth(0);

        String jobId      = getGetParameter("jobId");
        String reportData = getGetParameter("report");

        if (getLog().isDebugEnabled()) {
            getLog().debug("Report Data" + reportData);
        }

        CommanderUrlBuilder urlBuilder = createUrl("jobDetails.php")
                .setParameter("jobId", jobId);

        // noinspection HardCodedStringLiteral,StringConcatenation
        vPanel.add(new Anchor("Job: " + jobId, urlBuilder.buildString()));

        Widget htmlH1 = new HTML("<h1>UCS Query Report</h1>");

        vPanel.add(htmlH1);

        Widget htmlLabel = new HTML(
                "<p><span style=\"font-weight: bold;\">Content of the generated XML file:</span></p>");

        vPanel.add(htmlLabel);

        // formTable = getUIFactory().createFormTable();
        // callback("defectLinks", formTable);
        // vPanel.add(formTable.getWidget());
        List<List<String>> data = fillReport(reportData);
        Grid               grid = new Grid(data.size(), 2);

        if (!data.isEmpty()) {
            int numRows    = grid.getRowCount();
            int numColumns = grid.getColumnCount();

            for (int row = 0; row < numRows; row++) {

                for (int col = 0; col < numColumns; col++) {

                    if (col == 0) {

                        // set row's header as bold
                        grid.setWidget(row, 0,
                            new HTML(
                                "<span style=\"font-weight: bold;\">"
                                    + data.get(row)
                                          .get(0) + "</span>"));
                    }
                    else {

                        // print just plain text
                        grid.setWidget(row, col,
                            new Label(data.get(row)
                                          .get(col)));
                    }
                }
            }

            vPanel.add(grid);
        }

        rootPanel.add(vPanel);

        return rootPanel;
    }

    @SuppressWarnings("DynamicRegexReplaceableByCompiledPattern")
    private List<List<String>> fillReport(String data)
    {
        List<List<String>> reportData          = new ArrayList<List<String>>();
        String[]           reportMainDataArray = data.split(";;");

        for (String valueOnData : reportMainDataArray) {
            String[]     secondaryValueOnData = valueOnData.split("~~");
            List<String> myItemsFromElement   = new ArrayList<String>();

            for (String element : secondaryValueOnData) {
                myItemsFromElement.add(element);

                if (getLog().isDebugEnabled()) {
                    getLog().debug("Value:" + element + " ");
                }
            }

            if (myItemsFromElement.size() >= MINIMUM_ELEMENTS_PER_ROW) {
                reportData.add(myItemsFromElement);
            }
        }

        return reportData;
    }
}
