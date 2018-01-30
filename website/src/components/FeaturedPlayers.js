import React, { Component } from 'react';
import './FeaturedPlayers.css';
import FeaturedPlayerBox from './FeaturedPlayerBox';

class FeaturedPlayers extends Component {
    render() {
        let boxes = [];

        for (let i=0; i < this.props.entries.length; ++i) {
            let entry = this.props.entries[i];
            let rank = i+1;
            boxes.push(<FeaturedPlayerBox key={i} rank={rank} name={entry.username} wins={entry.wins} 
                                          losses={entry.losses} rating={entry.rating} head={entry.head}
                                          gender={entry.gender} kagClass={this.props.kagClass} />);
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
