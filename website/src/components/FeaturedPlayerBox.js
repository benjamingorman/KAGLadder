import React, { Component } from 'react';
import './FeaturedPlayerBox.css';
import CharacterPortrait from './CharacterPortrait';
import WinRatio from './WinRatio';
import {Link} from 'react-router-dom';

class FeaturedPlayerBox extends Component {
    render() {
        return (
            <div className="FeaturedPlayerBox">
                <div className="_rank">{this.props.rank}</div>
                <Link to={"/player/"+this.props.name}>
                    <CharacterPortrait head={this.props.head} gender={this.props.gender} kagClass={this.props.kagClass}
                        username={this.props.name} />
                    <div className="_username">{this.props.name}</div>
                    <div className="_rating">{this.props.rating}</div>
                    <WinRatio wins={this.props.wins} losses={this.props.losses} />
                </Link>
            </div>
            );
    }
}
export default FeaturedPlayerBox;
