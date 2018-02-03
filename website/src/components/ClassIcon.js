import React, { Component } from 'react';
import './ClassIcon.css';

class ClassIcon extends Component {
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
            <img className="ClassIcon" src={imgSrc} alt={this.props.kagClass} />
        );
    }
}
export default ClassIcon;
