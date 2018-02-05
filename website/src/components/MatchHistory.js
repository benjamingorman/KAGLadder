import React from 'react';
import './MatchHistory.css';
import MatchHistoryRow from './MatchHistoryRow';
import DynamicComponent from '../DynamicComponent';
import endpoints from '../endpoints';

class MatchHistory extends DynamicComponent {
    getEndpoints(props) {
        return {"recentMatchHistory": endpoints.recentMatchHistory};
    }

    render() {
        if (!this.isAllDynamicDataLoaded())
            return this.getLoadingDynamicContent();

        let entries = this.getDynamicData("recentMatchHistory");

        let rows = [];
        for (let i=0; i < entries.length; ++i) {
            let entry = entries[i];
            rows.push(<MatchHistoryRow key={i} id={entry.id} region={entry.region} player1={entry.player1} player2={entry.player2} 
                       kagClass={entry.kag_class} time={entry.match_time} player1Score={entry.player1_score}
                       player2Score={entry.player2_score}/>);
        }
        return (
            <div className="MatchHistory">
                <div className="_filter" />
                <div className="_rows">
                    {rows}
                </div>
            </div>
        );
    }
}
export default MatchHistory;
