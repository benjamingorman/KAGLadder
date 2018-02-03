import React, { Component } from 'react';
import './RadioGroup.css';

class RadioGroup extends Component {
    constructor(props) {
        super(props);
        this.state = {"selectedVal": this.props.default};
    }

    render() {
        let items = [];
        for (let i=0; i < this.props.children.length; ++i) {
            let child = this.props.children[i];
            let isSelected = child.props.value === this.state.selectedVal;
            let newProps = {key: i, selected: isSelected, onClick: () => this.handleChange(child.props.value)};
            items.push(React.cloneElement(child, newProps));
        }

        return (
            <div className="RadioGroup">
                {items}
            </div>
        );
    }

    handleChange(val) {
        //console.log("handleChange: ", val);
        this.setState({"selectedVal": val});
        if (this.props.onChange)
            this.props.onChange(val);
    }
}
export default RadioGroup;
