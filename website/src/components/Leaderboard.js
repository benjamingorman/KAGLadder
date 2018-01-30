import React from 'react';
import './Leaderboard.css';
import DynamicComponent from '../DynamicComponent';
import endpoints from '../endpoints';
import LeaderboardRow from './LeaderboardRow';
import FeaturedPlayers from './FeaturedPlayers';
import _ from 'lodash';

class Leaderboard extends DynamicComponent {
    getEndpoint(props) {
        return endpoints.leaderboard(props.region, props.kagClass);
    }

    render() {
        let sortedEntries = _.sortBy(this.state.dynamicData, entry => -entry.rating);

        let topEntries = sortedEntries.slice(0, 5);
        let bottomEntries = sortedEntries.slice(5);

        let rows = [];
        for (let i=0; i < bottomEntries.length; ++i) {
            let entry = bottomEntries[i];
            let rank = 5 + i + 1;
            //console.log(i, entry);
            rows.push(<LeaderboardRow key={i} rank={rank} name={entry.username} wins={entry.wins} 
                                      losses={entry.losses} rating={entry.rating} head={entry.head}
                                      gender={entry.gender} kagClass={this.props.kagClass} />);
        }

        return (
            <div className="Leaderboard">
                <FeaturedPlayers entries={topEntries} kagClass={this.props.kagClass} />
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
