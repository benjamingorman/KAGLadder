import React, { Component } from 'react';
import './RegionSelectButton.css';

class RegionSelectButton extends Component {
    render() {
        let flagUrl;
        switch(this.props.region) {
            case "Europe":
                flagUrl = "http://www.flags.net/images/largeflags/EUUN0001.GIF";
                break;
            case "United States":
                flagUrl = "http://www.flags.net/images/largeflags/UNST0001.GIF";
                break;
            case "Australia":
                flagUrl = "http://www.flags.net/images/largeflags/ASTL0001.GIF";
                break;
            default:
                flagUrl = "http://www.flags.net/images/largeflags/EUUN0001.GIF";
        }

        return (
            <div className={"RegionSelectButton " + (this.props.selected ? "selected" : "")} onClick={this.props.onClick}>
                <img src={flagUrl} alt={this.props.region} />
                <span>{this.props.region}</span>
            </div>
        );
    }
}
export default RegionSelectButton;
