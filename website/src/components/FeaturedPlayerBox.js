import React, { Component } from 'react';
import './FeaturedPlayerBox.css';
import CharacterPortrait from './CharacterPortrait';
import WinRatio from './WinRatio';

class FeaturedPlayerBox extends Component {
    render() {
        return (
            <div className="FeaturedPlayerBox">
                <div className="_rank">{this.props.rank}</div>
                <CharacterPortrait head={this.props.head} gender={this.props.gender} kagClass={this.props.kagClass} />
                <div className="_info">
                    <p class="nick">{this.props.name}</p>
                    <p>{this.props.rating}</p>
                    <WinRatio wins={this.props.wins} losses={this.props.losses} />
                </div>
            </div>
        );
    }
}
export default FeaturedPlayerBox;
