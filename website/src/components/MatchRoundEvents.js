import React, { Component } from 'react';
import './MatchRoundEvents.css';
import MatchEventsParser from '../matchEventsParser';

class MatchRoundEvents extends Component {
    render() {
        let parser = new MatchEventsParser(this.props.eventsData);
        let rows = [];
        let key = 0;

        for (let i=0; i < parser.events.length; ++i) {
            let [time, desc] = parser.describe(i);

            // The dangerouslySetInnerHtml thing allows the parser to return an html string
            // so that usernames can be styled.
            rows.push(
                <div key={key++} className="_row">
                    <span className="_time">{time}</span>
                    <span className="_desc" dangerouslySetInnerHTML={{__html: desc}}></span>
                </div>
            );

            let timeTilNextEvent = 0;
            if (i + 1 < parser.events.length) {
                timeTilNextEvent = parser.events[i+1].matchTime - parser.events[i].matchTime;
            }

            rows.push(
                <div key={key++}className="_empty _row" style={{minHeight: timeTilNextEvent+"px"}}>
                    <span className="_time"></span>
                    <span className="_desc"></span>
                </div>
            );
        }

        return (
            <div className="MatchRoundEvents">
                <h3>Timeline</h3>
                {rows}
            </div>
        );
    }
}
export default MatchRoundEvents;
