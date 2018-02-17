import React, { Component } from 'react';
import './FeaturedPlayers.css';
import FeaturedPlayerBox from './FeaturedPlayerBox';

class FeaturedPlayers extends Component {
    render() {
        let boxes = [];

        // Always show 5 boxes even if there's not actually data for 5 players
        for (let i=0; i < 5; ++i) {
            if (i < this.props.entries.length) {
                let entry = this.props.entries[i];
                let rank = i+1;
                boxes.push(<FeaturedPlayerBox key={i} rank={rank} name={entry.username} wins={entry.wins} nickname={entry.nickname}
                    clantag={entry.clantag} losses={entry.losses} rating={entry.rating} head={entry.head}
                    gender={entry.gender} kagClass={this.props.kagClass} />
                );
            }
            else {
                boxes.push(<FeaturedPlayerBox key={i} empty={true} rank={i+1} />);
            }
        }

        return (
            <div className="FeaturedPlayers">
                <div className="_top">
                    {boxes[0]}
                </div>
                <div className="_bottom">
                    {boxes.slice(1)}
                </div>
            </div>
        );
    }
}
export default FeaturedPlayers;
