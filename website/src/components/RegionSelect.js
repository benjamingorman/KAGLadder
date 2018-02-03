import React, { Component } from 'react';
import './RegionSelect.css';
import RadioGroup from './RadioGroup';
import RadioButton from './RadioButton';
import FlagIcon from './FlagIcon';

class RegionSelect extends Component {
    render() {
        return (
            <div className="RegionSelect">
                <RadioGroup onChange={this.props.onChange} default="EU">
                    <RadioButton value="EU">
                        <FlagIcon flag="EU" /> 
                        EU
                    </RadioButton>
                    <RadioButton value="US">
                        <FlagIcon flag="US" /> 
                        US
                    </RadioButton>
                    <RadioButton value="AUS">
                        <FlagIcon flag="AUS" /> 
                        AUS
                    </RadioButton>
                </RadioGroup>
            </div>
        );
    }
}
export default RegionSelect;
