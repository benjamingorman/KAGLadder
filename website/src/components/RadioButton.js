import React, { Component } from 'react';
import './RadioButton.css';

class RadioButton extends Component {
    render() {
        return (
            <div className={"RadioButton" + (this.props.selected ? " selected" : "")} onClick={this.props.onClick}>
                {this.props.children}
            </div>
        );
    }
}
export default RadioButton;
