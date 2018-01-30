import React from 'react';
import './MatchHistory.css';
import MatchHistoryRow from './MatchHistoryRow';
import DynamicComponent from '../DynamicComponent';
import endpoints from '../endpoints';

class MatchHistory extends DynamicComponent {
    getEndpoint(props) {
        return endpoints.matchHistory;
    }

    render() {
        let entries = [];
        if (this.state.dynamicData)
            entries = this.state.dynamicData;
        let rows = [];
        for (let i=0; i < entries.length; ++i) {
            let entry = this.state.dynamicData[i];
            rows.push(<MatchHistoryRow key={i} region={entry.region} player1={entry.player1} player2={entry.player2} 
                       kagClass={entry.kag_class} time={entry.match_time} player1Score={entry.player1_score}
                       player2Score={entry.player2_score}/>);
        }
        return (
            <div className="MatchHistory">
                <div className="_filter" />
                <table>
                    <thead>
                        <tr>
                            <th>Region</th>
                            <th>Class</th>
                            <th></th>
                            <th>Date</th>
                            <th>Time</th>
                        </tr>
                    </thead>
                    <tbody>
                        {rows}
                    </tbody>
                </table>
            </div>
        );
    }
}
export default MatchHistory;
