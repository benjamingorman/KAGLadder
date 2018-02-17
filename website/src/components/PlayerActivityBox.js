import React, { Component } from 'react';
import './PlayerActivityBox.css';
import CalendarHeatmap from 'react-calendar-heatmap';
//import ReactTooltip from 'react-tooltip';

class PlayerActivityBox extends Component {
    render() {
        let today = new Date(); 
        let threeMonthsAgo = new Date();
        threeMonthsAgo.setMonth(today.getMonth() - 3);

        // Count the number of matches played on each day
        let dateCounts = {};
        for (let matchHistory of this.props.matches) {
            let mt = matchHistory.match_time;
            let md = new Date(mt * 1000);
            let md_string = md.toDateString();

            if (!(md_string in dateCounts))
                dateCounts[md_string] = 0;
            dateCounts[md_string]++;
        }

        let heatmapValues = [];
        for (let md_string in dateCounts) {
            let dt = new Date(md_string);
            let val = {date: dt, count: dateCounts[md_string]};
            heatmapValues.push(val);
        }

        let classForValue = function(val) {
            if (!val) {
                return 'heatmap-color-0';
            }
            else if (val.count >= 20) {
                return 'heatmap-color-5';
            }
            else if (val.count >= 15) {
                return 'heatmap-color-4';
            }
            else if (val.count >= 10) {
                return 'heatmap-color-3';
            }
            else if (val.count >= 5) {
                return 'heatmap-color-2';
            }
            return 'heatmap-color-1';
        }

        let customTitleForValue = function(val) {
            if (val) {
                let date_string = val.date.toDateString();
                return `${date_string}\nGames played: ${val.count}`;
            }
        }

        const customTooltipDataAttrs = {};

        return (
            <div className="PlayerActivityBox box">
                <div className="_box_label">Activity</div>
                <div className="_heatmap grid-centered">
                    <CalendarHeatmap
                        startDate={threeMonthsAgo}
                        endDate={today}
                        values={heatmapValues}
                        classForValue={classForValue}
                        tooltipDataAttrs={customTooltipDataAttrs}
                        titleForValue={customTitleForValue}
                        showWeekdayLabels={false}
                    />
                </div>
            </div>
        );
    }
}
export default PlayerActivityBox;
