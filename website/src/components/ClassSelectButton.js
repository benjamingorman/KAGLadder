import React, { Component } from 'react';
import './ClassSelectButton.css';
import * as utils from '../utils';

class ClassSelectButton extends Component {
    render() {
        let imgSrc;
        switch(this.props.kagClass) {
            case "knight":
                imgSrc = "knight_icon.png";
                break;
            case "archer":
                imgSrc = "archer_icon.png";
                break;
            case "builder":
                imgSrc = "builder_icon.png";
                break;
            default:
                imgSrc = "knight_icon.png";
        }

        return (
            <div className={"ClassSelectButton " + (this.props.selected ? "selected" : "")} onClick={this.props.onClick}>
                <img src={imgSrc} alt={this.props.kagClass} />
                <span>{utils.capitalizeString(this.props.kagClass)}</span>
            </div>
        );
    }
}
export default ClassSelectButton;
