import React, { Component } from 'react';
import './Leaderboard.css';
import LeaderboardRow from './LeaderboardRow';
import FeaturedPlayers from './FeaturedPlayers';
import _ from 'lodash';

class Leaderboard extends Component {
    render() {
        let sortedEntries = _.sortBy(this.props.entries, entry => -entry.rating);

        let topEntries = sortedEntries.slice(0, 5);
        let bottomEntries = sortedEntries.slice(5);

        let rows = [];
        for (let i=0; i < bottomEntries.length; ++i) {
            let entry = bottomEntries[i];
            let rank = 5 + i + 1;
            rows.push(<LeaderboardRow key={i} rank={rank} name={entry.name} wins={entry.wins} 
                                      losses={entry.losses} rating={entry.rating} head={entry.head}
                                      gender={entry.gender} kagClass={entry.kagClass} />);
        }

        return (
            <div className="Leaderboard">
                <FeaturedPlayers entries={topEntries} />
                <table className="Leaderboard-table">
                    <thead>
                        <tr className="Leaderboard-table-header">
                            <th className="rank">Rank</th>
                            <th className="name">Name</th>
                            <th className="winratio">Win Ratio</th>
                            <th className="rating">Rating</th>
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
export default Leaderboard;
