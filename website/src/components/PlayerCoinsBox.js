import React, { Component } from 'react';
import './PlayerCoinsBox.css';

class PlayerCoinsBox extends Component {
    render() {

        return (
            <div className="PlayerCoinsBox box">
                <div className="_box_label">Coins</div>
                <div className="_inner">
                    <img className="_coin" src="coin.png" alt="coins" />
                    <span className="_coins">{this.props.coins || 0}</span>
                </div>
            </div>
        );
    }
}
export default PlayerCoinsBox;
